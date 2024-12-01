Shader "Demo/Hair"
{
    Properties
    {
        _AlphaMap("AlphaMap", 2D) = "white" {}

        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}
        _NormalMap("NormalMap", 2D) = "bump" {}
        _NormalScale("NormalScale",Range(0,1)) = 1
        _Scatter("Scatter",Range(0,1)) = 1
        _RoughnessMap("RoughnessMap", 2D) = "white" {}
        _Roughness("Roughness",Range(0,1)) = 0
        _AOMap("AOMap", 2D) = "white" {}
        _AO("AO",Range(0,1)) = 1
        _EnvRotation ("EnvRotation",Range(0,360)) = 0
    }

    SubShader
    {
        Name "ForwardLit"
        Tags
        {
            "LightMode" = "UniversalForward"
        }

        Pass
        {
            Name "ForwardLit"
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
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _FORWARD_PLUS

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
                float _NormalScale;
                float _Scatter;
                float _Roughness;
                float _AO;
                float _EnvRotation;
            CBUFFER_END

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            TEXTURE2D(_MetallicMap);
            SAMPLER(sampler_MetallicMap);

            TEXTURE2D(_RoughnessMap);
            SAMPLER(sampler_RoughnessMap);

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

                half alpha = SAMPLE_TEXTURE2D(_AlphaMap, sampler_AlphaMap, i.uv);

                half roughness = SAMPLE_TEXTURE2D(_RoughnessMap, sampler_RoughnessMap, i.uv);
                roughness = max(saturate(roughness * _Roughness), 0.001);
                half ao = SAMPLE_TEXTURE2D(_AOMap, sampler_AOMap, i.uv);
                ao = lerp(1, ao, _AO);


                float4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv);
                float3 normalTS = UnpackNormalScale(normalMap, _NormalScale);
                float3 biTangentWS = i.tangentWS.w * cross(i.normalWS.xyz, i.tangentWS.xyz);
                float3x3 tbn = float3x3(i.tangentWS.xyz, biTangentWS, i.normalWS.xyz);
                float3 normalWS = NormalizeNormalPerPixel(TransformTangentToWorldDir(normalTS, tbn));

                float3 viewWS = GetWorldSpaceNormalizeViewDir(i.positionWS);
                float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                float3 SH = SampleSHPixel(i.vertexSH, i.normalWS);

                float2 screenUV = GetNormalizedScreenSpaceUV(i.positionCS);

                #if defined(_SCREEN_SPACE_OCCLUSION)
                AmbientOcclusionFactor aoFactor;
                aoFactor = GetScreenSpaceAmbientOcclusion(screenUV);
                ao = min(ao,aoFactor.indirectAmbientOcclusion);
                #endif


                //------------------- brdf-----
                float3 diffuseColor = lerp(baseColor, 0, 0);
                float3 specularColor = lerp(float3(0.4, 0.4, 0.4), baseColor, 0);

                float3 direct = DirectLighting_float(diffuseColor, specularColor, roughness, i.positionWS, normalWS,
                                                 viewWS, _Scatter);
                float3 c = direct;

                clip(alpha-0.1);
                return float4(c, 1);
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