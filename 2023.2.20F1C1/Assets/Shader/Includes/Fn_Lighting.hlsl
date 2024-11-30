#ifndef LIGHTING_INCLUDE
#define LIGHTING_INCLUDE

#include "ShadingModel.hlsl"
#define UNITY_PI 3.141592653589793

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

float3 PBRIndirect(float3 DiffuseColor, float3 SpecularColor, float3 PositionWS, float3 V,
                   float3 N, float3 SH, half occlusion, float Roughness, float EnvRoation)
{
    half3 R = reflect(-V, N);
    R = RotateDirection(R, EnvRoation);
    float NoV = saturate(abs(dot(N, V)) + 0.001);

    float diffuseAO = AOMultiBounce(DiffuseColor, occlusion);
    float specularAO = AOMultiBounce(SpecularColor, occlusion);
    specularAO = GetSpecularOcclusion(NoV, Roughness, specularAO);
    
    float3 diffuse = DiffuseColor * SH * diffuseAO;
    float3 specularLD = GlossyEnvironmentReflection(R, PositionWS, Roughness, occlusion);
    float3 spcularDFG = EnvBRDFApprox(SpecularColor, Roughness, NoV);
    float3 spcular = specularLD * spcularDFG * specularAO;

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

    float3 specular = SpecularGGX_UE4(Roughness, SpecularColor, NoH, NoV, VoH, NoL) * UNITY_PI;
    float3 diffuse = Diffuse_Lambert_UE4(DiffuseColor);
    float3 c = specular + diffuse;
    return c * radiance;
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

float3 SimpleShading(float3 DiffuseColor, float3 SpecularColor, float Roughness, Light light, float3 V,
                     half3 N)
{
    float3 L = light.direction;
    float atten = light.shadowAttenuation * light.distanceAttenuation;
    float3 lightColor = light.color;

    float NoL = saturate(dot(N, L));
    float3 H = normalize(V + L);
    float NoH = saturate(dot(N, H));

    // Generalized microfacet specular
    float D = D_GGX_UE4(Pow4(Roughness), NoH);
    float Vis = Vis_Implicit_UE4();
    float3 F = F_None_UE4(SpecularColor);
    float3 diffuse = Diffuse_Lambert_UE4(DiffuseColor);
    float3 spec = (D * Vis) * F;
    float3 color = diffuse + spec;

    return color * NoL * lightColor * atten;
}

#endif
