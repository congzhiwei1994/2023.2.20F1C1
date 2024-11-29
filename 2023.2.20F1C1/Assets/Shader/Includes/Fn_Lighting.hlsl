#ifndef LIGHTING_INCLUDE
#define LIGHTING_INCLUDE

#include "ShadingModel.hlsl"


float3 SpecularGGX_UE4(float Roughness, float3 SpecularColor, float NoH, float NoV, float VoH, float NoL)
{
    float a2 = Pow4(Roughness);

    // Generalized microfacet specular
    float D = D_GGX_UE4(a2, NoH);
    float Vis = Vis_SmithJointApprox_UE4(a2, NoV, NoL);
    float3 F = F_Schlick_UE4(SpecularColor, VoH);

    return (D * Vis) * F;
}

float3 PBRLighting_UE4(float Roughness, float3 DiffuseColor, float3 SpecularColor, float3 V,
                       float3 N, Light light)
{
    float3 L = light.direction;
    float atten = light.shadowAttenuation * light.distanceAttenuation;
    float3 lightColor = light.color;

    float3 H = normalize(L + V);
    float NoL = saturate(dot(N, L));
    float NoH = saturate(dot(N, H));
    float NoV = saturate(abs(dot(N, V)) + 0.001);
    float VoH = saturate(dot(V, H));

    float3 specular = SpecularGGX_UE4(Roughness, SpecularColor, NoH, NoV, VoH, NoL);
    float3 diffuse = Diffuse_Lambert_UE4(DiffuseColor);
    float3 c = specular + diffuse;

    return c * NoL * lightColor * atten;
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
