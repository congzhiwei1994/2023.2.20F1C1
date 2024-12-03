Shader "Demo/Hair"
{
    Properties
    {
        _AlphaMap("AlphaMap", 2D) = "white" {}
        _ClipOff("ClipOff",Range(0,1)) = 0.1
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}
        _NoiseMap("NoiseMap", 2D) = "white" {}
        _NoiseIntensity("NoiseIntensity",Range(0,1)) = 1
        _Scatter("Scatter",Range(0,1)) = 1
        _Roughness("Roughness",Range(0,1)) = 0
        _Specular("Specular",Range(0,1)) = 0.5
        _AOMap("AOMap", 2D) = "white" {}
        _AO("AO",Range(0,1)) = 1
        _EnvRotation ("EnvRotation",Range(0,360)) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType" = "TransparentCutout"
        }

        Pass
        {
            Name "HairPassAlphaTest"
            Tags
            {
                "LightMode" = "HairPassAlphaTest"
            }

            Cull Back
            ZWrite on

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Includes/Fn_HairLighting.hlsl"
            #define _NORMALMAP

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

                float3 positionWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                float4 tangentWS : TEXCOORD4;
                float3 viewDirWS : TEXCOORD5;
                float4 shadowCoord : TEXCOORD7;
                float4 positionCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _NoiseIntensity;
                float _Specular;
                float _Scatter;
                float _Roughness;
                float _AO;
                float _EnvRotation;
                float _ClipOff;
            CBUFFER_END

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_NoiseMap);
            SAMPLER(sampler_NoiseMap);

            TEXTURE2D(_AOMap);
            SAMPLER(sampler_AOMap);

            TEXTURE2D(_AlphaMap);
            SAMPLER(sampler_AlphaMap);


            Varyings vert(Attributes input)
            {
                Varyings o = (Varyings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                real sign = input.tangentOS.w * GetOddNegativeScale();
                half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);

                o.uv = input.texcoord;
                o.shadowCoord = GetShadowCoord(vertexInput);
                o.positionWS = vertexInput.positionWS;
                o.normalWS = normalInput.normalWS;
                o.tangentWS = tangentWS;
                o.vertexSH = OUTPUT_SH4(o.positionWS, o.normalWS.xyz,
                                        GetWorldSpaceNormalizeViewDir(o.positionWS), o.vertexSH);
                o.positionCS = vertexInput.positionCS;

                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                baseColor = baseColor * _BaseColor;

                float Roughness = max(0.001, _Roughness);
                half ao = SAMPLE_TEXTURE2D(_AOMap, sampler_AOMap, i.uv);
                ao = lerp(1, ao, _AO);

                half alpha = SAMPLE_TEXTURE2D(_AlphaMap, sampler_AlphaMap, i.uv);
                half noiseMap = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, i.uv);
                float3 noise = lerp(float3(0, 0, -1), float3(0, 0, 1), noiseMap) * _NoiseIntensity;
                noise += float3(0, 1, 0);

                float3 biTangentWS = i.tangentWS.w * cross(i.normalWS.xyz, i.tangentWS.xyz);
                float3x3 tbn = float3x3(i.tangentWS.xyz, biTangentWS, i.normalWS.xyz);
                float3 normalWS = NormalizeNormalPerPixel(TransformTangentToWorldDir(noise, tbn));

                float3 viewWS = GetWorldSpaceNormalizeViewDir(i.positionWS);
                float2 screenUV = GetNormalizedScreenSpaceUV(i.positionCS);

                #if defined(_SCREEN_SPACE_OCCLUSION)
                AmbientOcclusionFactor aoFactor;
                aoFactor = GetScreenSpaceAmbientOcclusion(screenUV);
                ao = min(ao,aoFactor.indirectAmbientOcclusion);
                #endif

                float3 direct = DirectLighting_float(baseColor, _Specular, Roughness, i.positionWS, normalWS, viewWS,
                                                     _Scatter);
                float3 indirect = IndirectLighting(baseColor, _Specular, Roughness, i.positionWS, normalWS, viewWS,
                                                   _Scatter, ao, _EnvRotation);

                float3 c = direct + indirect;
                clip(alpha - _ClipOff);

                return float4(c, alpha);
            }
            ENDHLSL
        }

        Pass
        {
            Name "HairPassAlphaBlend"
            Tags
            {
                "LightMode" = "HairPassAlphaBlend"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite off
            ZTest Less

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Includes/Fn_HairLighting.hlsl"
            #define _NORMALMAP

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

                float3 positionWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                float4 tangentWS : TEXCOORD4;
                float3 viewDirWS : TEXCOORD5;
                float4 shadowCoord : TEXCOORD7;
                float4 positionCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _NoiseIntensity;
                float _Specular;
                float _Scatter;
                float _Roughness;
                float _AO;
                float _EnvRotation;
                float _ClipOff;
            CBUFFER_END

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_NoiseMap);
            SAMPLER(sampler_NoiseMap);

            TEXTURE2D(_AOMap);
            SAMPLER(sampler_AOMap);

            TEXTURE2D(_AlphaMap);
            SAMPLER(sampler_AlphaMap);


            Varyings vert(Attributes input)
            {
                Varyings o = (Varyings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                real sign = input.tangentOS.w * GetOddNegativeScale();
                half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);

                o.uv = input.texcoord;
                o.shadowCoord = GetShadowCoord(vertexInput);
                o.positionWS = vertexInput.positionWS;
                o.normalWS = normalInput.normalWS;
                o.tangentWS = tangentWS;
                o.vertexSH = OUTPUT_SH4(o.positionWS, o.normalWS.xyz,
                                        GetWorldSpaceNormalizeViewDir(o.positionWS), o.vertexSH);
                o.positionCS = vertexInput.positionCS;

                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                baseColor = baseColor * _BaseColor;

                float Roughness = max(0.001, _Roughness);
                half ao = SAMPLE_TEXTURE2D(_AOMap, sampler_AOMap, i.uv);
                ao = lerp(1, ao, _AO);

                half alpha = SAMPLE_TEXTURE2D(_AlphaMap, sampler_AlphaMap, i.uv);
                half noiseMap = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, i.uv);
                float3 noise = lerp(float3(0, 0, -1), float3(0, 0, 1), noiseMap) * _NoiseIntensity;
                noise += float3(0, 1, 0);

                float3 biTangentWS = i.tangentWS.w * cross(i.normalWS.xyz, i.tangentWS.xyz);
                float3x3 tbn = float3x3(i.tangentWS.xyz, biTangentWS, i.normalWS.xyz);
                float3 normalWS = NormalizeNormalPerPixel(TransformTangentToWorldDir(noise, tbn));

                float3 viewWS = GetWorldSpaceNormalizeViewDir(i.positionWS);
                float2 screenUV = GetNormalizedScreenSpaceUV(i.positionCS);

                #if defined(_SCREEN_SPACE_OCCLUSION)
                AmbientOcclusionFactor aoFactor;
                aoFactor = GetScreenSpaceAmbientOcclusion(screenUV);
                ao = min(ao,aoFactor.indirectAmbientOcclusion);
                #endif

                float3 direct = DirectLighting_float(baseColor, _Specular, Roughness, i.positionWS, normalWS, viewWS,
                                                     _Scatter);
                float3 indirect = IndirectLighting(baseColor, _Specular, Roughness, i.positionWS, normalWS, viewWS,
                                                   _Scatter, ao, _EnvRotation);

                float3 c = direct + indirect;
                
                return float4(c, alpha);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Universal Pipeline keywords

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ColorMask R
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // -------------------------------------
            // Universal Pipeline keywords
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }
    }
}