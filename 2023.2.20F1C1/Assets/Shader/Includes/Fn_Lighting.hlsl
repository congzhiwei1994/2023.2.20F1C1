#ifndef LIGHTING_INCLUDE
#define LIGHTING_INCLUDE

#include "ShadingModel.hlsl"
#define UNITY_PI 3.141592653589793

float GetCurvature(float SSSRange, float SSSPower, float3 WorldNormal, float3 WorldPos)
{
    float deltaWorldNormal = length(abs(ddx_fine(WorldNormal)) + abs(ddy_fine(WorldNormal)));
    float deltaWorldPosition = length(abs(ddx_fine(WorldPos)) + abs(ddy_fine(WorldPos))) / 0.001;
    float Curvature = saturate(SSSRange + deltaWorldNormal / deltaWorldPosition * SSSPower);

    return Curvature;
}


inline half3 RotateDirection(half3 R, half degrees = 0)
{
    float3 reflUVW = R;
    half theta = degrees * PI / 180.0f;
    half costha = cos(theta);
    half sintha = sin(theta);
    reflUVW = half3(reflUVW.x * costha - reflUVW.z * sintha, reflUVW.y, reflUVW.x * sintha + reflUVW.z * costha);
    return reflUVW;
}

// Indirect Specular AO
float GetSpecularOcclusion(float NoV, float Roughness, float AO)
{
    float a2 = Roughness * Roughness;
    return saturate(pow(NoV + AO, a2) - 1 + AO);
}

// Indirect Diffuse AO
float3 AOMultiBounce(float3 BaseColor, float AO)
{
    float3 a = 2.0404 * BaseColor - 0.3324;
    float3 b = -4.7951 * BaseColor + 0.6417;
    float3 c = 2.7552 * BaseColor + 0.6903;
    return max(AO, ((AO * a + b) * AO + c) * AO);
}


float3 SpecularGGX_UE4(float Roughness, float3 SpecularColor, float NoH, float NoV, float VoH, float NoL)
{
    float a2 = Pow4(Roughness);

    // Generalized microfacet specular
    float D = D_GGX_UE4(a2, NoH);
    float Vis = Vis_SmithJointApprox_UE4(a2, NoV, NoL);
    float3 F = F_Schlick_UE4(SpecularColor, VoH);
    return (D * Vis) * F;
}

float3 DualSpecularGGX(float Lube0Roughness, float Lube1Roughness, float LubeMix, float3 SpecularColor, float NoH,
                       float NoV, float VoH, float NoL)
{
    float a0 = Pow4(Lube0Roughness);
    float a1 = Pow4(Lube1Roughness);
    float a = Pow4((Lube0Roughness + Lube1Roughness) * 0.5);

    // Generalized microfacet specular
    float D0 = D_GGX_UE4(a0, NoH);
    float D1 = D_GGX_UE4(a1, NoH);
    float D = lerp(D0, D1, 1 - LubeMix);

    float Vis = Vis_SmithJointApprox_UE4(a, NoV, NoL);
    float3 F = F_Schlick_UE4(SpecularColor, VoH);
    return (D * Vis) * F;
}

float3 EnvSpecularDFG(float3 R, float3 SpecularColor, float3 PositionWS, float3 V,
                      float NoV, half occlusion, float Roughness)
{
    float3 specularLD = GlossyEnvironmentReflection(R, PositionWS, Roughness, occlusion);
    float3 spcularDFG = EnvBRDFApprox(SpecularColor, Roughness, NoV);
    return specularLD * spcularDFG;
}

float3 PBRIndirect(float3 DiffuseColor, float3 SpecularColor, float3 PositionWS, float3 V,
                   float3 N, float3 SH, half occlusion, float Roughness,
                   float EnvRoation)
{
    half3 R = reflect(-V, N);
    R = RotateDirection(R, EnvRoation);
    float NoV = saturate(abs(dot(N, V)) + 0.001);

    float diffuseAO = AOMultiBounce(DiffuseColor, occlusion);
    float specularAO = AOMultiBounce(SpecularColor, occlusion);
    specularAO = GetSpecularOcclusion(NoV, Roughness, specularAO);

    float3 diffuse = DiffuseColor * SH * diffuseAO;
    float3 spcular = EnvSpecularDFG(R, SpecularColor, PositionWS, V, NoV, occlusion, Roughness) * specularAO;

    float3 c = diffuse + spcular;
    return c;
}


float3 PBRDirect_UE4(float3 DiffuseColor, float3 SpecularColor, float3 V,
                     float3 N, float3 L, float3 lightColor, float atten, float Roughness)
{
    float3 H = normalize(L + V);
    float NoL = saturate(dot(N, L));
    float NoH = saturate(dot(N, H));
    float NoV = saturate(abs(dot(N, V)) + 0.001);
    float VoH = saturate(dot(V, H));

    float3 radiance = NoL * lightColor * atten;

    float3 specular = SpecularGGX_UE4(Roughness, SpecularColor, NoH, NoV, VoH, NoL);
    float3 diffuse = Diffuse_Lambert_UE4(DiffuseColor);
    float3 c = specular + diffuse;
    return c * radiance * UNITY_PI;
}

float3 PBRLighting_Unity(float3 DiffuseColor, float3 SpecularColor, float3 V,
                         float3 N, float3 L, float Roughness)
{
    float3 H = normalize(L + V);
    float NoL = saturate(dot(N, L));
    float NoH = saturate(dot(N, H));
    float NoV = saturate(abs(dot(N, V)) + 0.001);
    float VoH = saturate(dot(V, H));

    float3 diffuse = DisneyDiffuse_Unity(NoV, NoV, VoH, Roughness) * DiffuseColor;
    float Vis = SmithJointGGXVisibilityTerm_Unity(NoL, NoV, Roughness * Roughness);
    float D = GGXTerm_Unity(NoH, Roughness * Roughness);
    float3 F = FresnelTerm_Unity(SpecularColor, NoL);
    float3 specular = Vis * D * F * UNITY_PI;
    float3 color = diffuse + specular;
    return color * NoL;
}

float3 SkinIndirect(float3 DiffuseColor, float3 SpecularColor, float3 PositionWS, float3 V,
                    float3 N, float3 SH, half occlusion, float Lube0Roughness, float Lube1Roughness, float LubeMix,
                    float EnvRoation, float mainShadow)
{
    float Roughness = (Lube0Roughness + Lube1Roughness) * 0.5;

    half3 R = reflect(-V, N);
    R = RotateDirection(R, EnvRoation);
    float NoV = saturate(abs(dot(N, V)) + 0.001);

    float diffuseAO = AOMultiBounce(DiffuseColor, occlusion);
    float specularAO = AOMultiBounce(SpecularColor, occlusion);
    specularAO = GetSpecularOcclusion(NoV, Roughness, specularAO);

    float3 diffuse = DiffuseColor * SH * diffuseAO;
    float3 lube0spcular = EnvSpecularDFG(R, SpecularColor, PositionWS, V,
                                         NoV, occlusion, Lube0Roughness);
    float3 lube1spcular = EnvSpecularDFG(R, SpecularColor, PositionWS, V,
                                         NoV, occlusion, Lube1Roughness);

    float3 specular = lerp(lube0spcular, lube1spcular, 1 - LubeMix) * specularAO;

    // 消弱背面的IBL
    specular = lerp(specular * 0.3f, specular, mainShadow);

    float3 c = diffuse + specular;
    return c;
}

float3 SkinDirect(Texture2D _SSSLUTMAP, SamplerState sampler_SSSLUTMAP, float3 DiffuseColor, float3 SpecularColor,
                  float3 V, float3 N, float3 N_blur, float3 L, float3 lightColor, float atten, float3 mainShadowColor,
                  float Lube0Roughness,
                  float Lube1Roughness, float LubeMix, float Curvature)
{
    float3 H = normalize(L + V);
    float NoL = dot(N, L) * 0.5 + 0.5;
    float NoL_Blur = dot(N_blur, L) * 0.5 + 0.5;
    float NoL_Specular = saturate(dot(N, L));
    float NoH = saturate(dot(N, H));
    float NoV = saturate(abs(dot(N, V)) + 0.001);
    float VoH = saturate(dot(V, H));

    float NoL_R = NoL_Blur;
    float NoL_G = lerp(NoL_Blur, NoL, 0.6);
    float NoL_B = lerp(NoL_Blur, NoL, 0.2);

    float3 lutMap_R = SAMPLE_TEXTURE2D(_SSSLUTMAP, sampler_SSSLUTMAP, float2(NoL_R,Curvature));
    float3 lutMap_G = SAMPLE_TEXTURE2D(_SSSLUTMAP, sampler_SSSLUTMAP, float2(NoL_G,Curvature));
    float3 lutMap_B = SAMPLE_TEXTURE2D(_SSSLUTMAP, sampler_SSSLUTMAP, float2(NoL_B,Curvature));
    float3 lutMap = (lutMap_R + lutMap_G + lutMap_B) / 3;

    float3 radiance_Diffuse = lutMap * lightColor * mainShadowColor;
    float3 radiance_Specular = NoL_Specular * lightColor * atten;

    float3 specular = DualSpecularGGX(Lube0Roughness, Lube1Roughness, LubeMix, SpecularColor, NoH, NoV, VoH,
                                      NoL_Specular);
    specular *= radiance_Specular;

    float3 diffuse = Diffuse_Lambert_UE4(DiffuseColor) * radiance_Diffuse;
    float3 c = specular + diffuse;

    return c * UNITY_PI;
}


float3 SkinLighting(Texture2D _SSSLUTMAP, SamplerState sampler_SSSLUTMAP, float3 DiffuseColor, float3 SpecularColor,
                    float3 viewWS, float3 positionWS, float3 normalWS, float3 N_blur,
                    float Lube0Roughness, float Lube1Roughness, float LubeMix, float ao,
                    float EnvRotation, float SSSRange, float SSSPower)
{
    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    Light light = GetMainLight(shadowCoord, positionWS, 1);
    float mainShadow = saturate(light.shadowAttenuation + 0.2);
    float3 mainShadowColor = lerp(float3(0.11, 0.025, 0.012), float3(1, 1, 1), mainShadow);
    float atten = mainShadowColor * light.distanceAttenuation;

    float curvature = GetCurvature(SSSRange, SSSPower, normalWS, positionWS);
    float3 directLighting = SkinDirect(_SSSLUTMAP, sampler_SSSLUTMAP, DiffuseColor,
                                       SpecularColor, viewWS, normalWS, N_blur, light.direction, light.color, atten,
                                       mainShadowColor, Lube0Roughness, Lube1Roughness, LubeMix, curvature);

    float3 indirectLighting;
    {
        float3 sh = SampleSH(normalWS);
        indirectLighting = SkinIndirect(DiffuseColor, SpecularColor, positionWS,
                                        viewWS, normalWS, sh, ao, Lube0Roughness, Lube1Roughness, LubeMix,
                                        EnvRotation, light.shadowAttenuation);
    }

    float3 c = directLighting + indirectLighting;
    /**
        #if defined(_ADDITIONAL_LIGHTS)
        uint pixelLightCount = GetAdditionalLightsCount();
    
        #if USE_FORWARD_PLUS
        for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
        {
            FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK
    
            Light light = GetAdditionalLight(lightIndex, positionWS);
            {
                    atten = light.distanceAttenuation * light.shadowAttenuation;
                    c += PBRDirect_UE4(DiffuseColor, SpecularColor, viewWS, normalWS, light.direction,
                                                       light.color, atten, roughness);
            }
        }
        #endif
    
        LIGHT_LOOP_BEGIN(pixelLightCount)
             Light light = GetAdditionalLight(lightIndex, positionWS);
            {
      
                    atten = light.distanceAttenuation * light.shadowAttenuation;
                    c += PBRDirect_UE4(DiffuseColor, SpecularColor, viewWS, normalWS, light.direction,
                                               light.color, atten, roughness);
                
    
            }
        LIGHT_LOOP_END
        #endif
    **/
    return c;
}

float3 StanderdPBRLighting(float3 DiffuseColor, float3 SpecularColor, float3 viewWS, float3 positionWS, float3 normalWS,
                           float roughness, float ao, float EnvRotation)
{
    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);

    Light light = GetMainLight(shadowCoord, positionWS, 1);
    float atten = light.distanceAttenuation * light.shadowAttenuation;

    float3 directLighting;
    {
        directLighting = PBRDirect_UE4(DiffuseColor, SpecularColor, viewWS, normalWS, light.direction,
                                       light.color, atten, roughness);
    }

    float3 indirectLighting;
    {
        float3 sh = SampleSH(normalWS);
        indirectLighting = PBRIndirect(DiffuseColor, SpecularColor, positionWS,
                                       viewWS, normalWS, sh, ao, roughness,
                                       EnvRotation);
    }

    float3 c = directLighting + indirectLighting;

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_FORWARD_PLUS
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, positionWS);
        {
                atten = light.distanceAttenuation * light.shadowAttenuation;
                c += PBRDirect_UE4(DiffuseColor, SpecularColor, viewWS, normalWS, light.direction,
                                                   light.color, atten, roughness);
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
         Light light = GetAdditionalLight(lightIndex, positionWS);
        {
  
                atten = light.distanceAttenuation * light.shadowAttenuation;
                c += PBRDirect_UE4(DiffuseColor, SpecularColor, viewWS, normalWS, light.direction,
                                           light.color, atten, roughness);
            

        }
    LIGHT_LOOP_END
    #endif

    return c;
}


#endif
