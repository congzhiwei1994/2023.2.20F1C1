Shader "Demo/Eye"
{
    Properties
    {

        _ScaleUVsByCenter("_ScaleUVsByCenter",Range(0,1)) = 1
        _PupilScale("瞳孔PupilScale",Range(0,1)) = 1

        [Space(10)]
        [Header(Scalera)]
        _ScaleraMap("巩膜_ScaleraMap", 2D) = "white" {}
        _ScaleraBrightness("ScaleraBrightness",Range(0,3)) = 1
        _ScaleraNormalMap("_ScaleraNormalMap", 2D) = "bump" {}
        _ScaleraNormalUVScale("_ScaleraNormalUVScale",Range(0,2)) = 1
        _ScaleraNormalScale("_ScaleraNormalScale",Range(0,1)) = 1

        [Space(10)]
        [Header(Iris)]
        _IrisMap("IrisMap 虹膜", 2D) = "white" {}
        _IrisBrightness("虹膜IrisBrightness",Range(0,3)) = 1
        _IrisRadius("虹膜IrisRadius",Range(0,1)) = 1


        [Space(10)]
        [Header(Refrect)]
        _MidPlaneHeightMap("MidPlaneHeightMap", 2D) = "white" {}
        _IrisDepthScala("IrisDepthScala",Range(0,2)) = 1
        _IOR("IOR",float) = 1.45
        _EyeDirection("EyeDirection", 2D) = "bump" {}

        [Space(10)]
        [Header(Limbus)]
        _LimbusPower("(角膜缘)Limbus Power",Range(1,10)) = 5
        _LimbusScale("(角膜缘)Limbus Scale",Range(0.001,1)) = 0.2

        [Space(10)]
        [Header(Lirgting)]
        _ScaleraSpecular("【巩膜】ScaleraSpecular",Range(0,1)) = 0.25
        _CorneaSpecular("【角膜】CorneaSpecular",Range(0,1)) = 0.5

        _ScaleraRoughness("【巩膜】_ScaleraRoughness",Range(0,1)) = 0.5
        _CorneaRoughness("【角膜】_CorneaRoughness",Range(0,1)) = 0.2

        //        _NormalMap("NormalMap", 2D) = "bump" {}
        //        _NormalScale("NormalScale",Range(0,1)) = 1
        //        _MetallicMap("MetallicMap", 2D) = "white" {}
        //        _Metallic("Metallic",Range(0,1)) = 1
        //        _RoughnessMap("RoughnessMap", 2D) = "white" {}
        //        _Roughness("Roughness",Range(0,1)) = 0
        //        _AOMap("AOMap", 2D) = "white" {}
        //        _AO("AO",Range(0,1)) = 1
        //        _EnvRotation ("EnvRotation",Range(0,360)) = 0


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

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Includes/Fn_EyeLighting.hlsl"
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
                float _LimbusScale;
                float _AO;
                float _EnvRotation;
                float _ScaleUVsByCenter;
                float _ScaleraBrightness;
                float _PupilScale;
                float _IrisBrightness;
                float _IrisRadius;
                float _IrisDepthScala;
                float _IOR;
                float _LimbusPower;
                float _ScaleraSpecular;
                float _CorneaSpecular;
                float _CorneaRoughness;
                float _ScaleraRoughness;
                float _ScaleraNormalScale;
                float _ScaleraNormalUVScale;
            CBUFFER_END

            TEXTURE2D(_ScaleraMap);
            SAMPLER(sampler_ScaleraMap);

            TEXTURE2D(_IrisMap);
            SAMPLER(sampler_IrisMap);

            TEXTURE2D(_MidPlaneHeightMap);
            SAMPLER(sampler_MidPlaneHeightMap);

            TEXTURE2D(_EyeDirection);
            SAMPLER(sampler_EyeDirection);

            TEXTURE2D(_ScaleraNormalMap);
            SAMPLER(sampler_ScaleraNormalMap);

            TEXTURE2D(_RoughnessMap);
            SAMPLER(sampler_RoughnessMap);

            TEXTURE2D(_AOMap);
            SAMPLER(sampler_AOMap);


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
                float3 biTangentWS = i.tangentWS.w * cross(i.normalWS.xyz, i.tangentWS.xyz);
                float3x3 tbn = float3x3(i.tangentWS.xyz, biTangentWS, i.normalWS.xyz);
                float3 viewWS = GetWorldSpaceNormalizeViewDir(i.positionWS);

                float scaleUVsByCenter = _ScaleUVsByCenter;
                float irisRadius = _IrisRadius;
                float2 eyeBallUV = ScaleUVsByCenter(i.uv, scaleUVsByCenter);
                // 巩膜
                half4 scaleraMap = SAMPLE_TEXTURE2D(_ScaleraMap, sampler_ScaleraMap, eyeBallUV) * _ScaleraBrightness;
                half2 scaleNormalUV = ScaleUVsByCenter(i.uv, _ScaleraNormalUVScale);
                half3 scaleraNormalMap = UnpackNormalScale(
                    SAMPLE_TEXTURE2D(_ScaleraNormalMap, sampler_ScaleraNormalMap, scaleNormalUV), _ScaleraNormalScale);
                half3 scaleraNormal = NormalizeNormalPerPixel(TransformTangentToWorldDir(scaleraNormalMap, tbn));

                // 计算虹膜的高度
                half heightMap = SAMPLE_TEXTURE2D(_MidPlaneHeightMap, sampler_MidPlaneHeightMap, i.uv);
                half2 depthUV = float2(scaleUVsByCenter * irisRadius + 0.5, 0.5);
                half depthMap = SAMPLE_TEXTURE2D(_MidPlaneHeightMap, sampler_MidPlaneHeightMap, depthUV);
                half depth = max(0, heightMap - depthMap) * _IrisDepthScala;

                // 计算眼睛的方向
                float3 eyeDirectTS = UnpackNormal(SAMPLE_TEXTURE2D(_EyeDirection, sampler_EyeDirection, i.uv));
                float3 eyeDirectWS = NormalizeNormalPerPixel(TransformTangentToWorldDir(eyeDirectTS, tbn));

                // 计算屈光体的折射
                float3 eyeRefract = EyeRefraction(eyeBallUV, i.normalWS, viewWS, _IOR, irisRadius, depth, eyeDirectWS,
                                                  i.tangentWS.xyz);
                // 计算被折射之后的虹膜UV
                float2 irisUV_refract = eyeRefract.xy;
                // 计算被折射之后的虹膜凹度
                float irisConcavity = eyeRefract.z;

                // 虹膜 
                float2 irisUV = ScaleUVFromCircle(irisUV_refract, _PupilScale);
                half4 irisMap = SAMPLE_TEXTURE2D(_IrisMap, sampler_IrisMap, irisUV) * _IrisBrightness;

                // 角膜缘
                float limbus = length((irisUV - float2(0.5, 0.5)) / _LimbusScale);
                limbus = saturate(1 - pow(limbus, _LimbusPower));

                // 虹膜遮罩， 用于区分虹膜/角膜和巩膜(眼白)
                half irisMask = distance(eyeBallUV, float2(0.5, 0.5)) - irisRadius + 0.045;
                irisMask = irisMask / 0.045;
                irisMask = smoothstep(0, 1, 1 - irisMask);

                float4 eyeColor = lerp(scaleraMap, irisMap * limbus, irisMask);
                float3 specularScale = lerp(_ScaleraSpecular, _CorneaSpecular, irisMask);
                half roughness = lerp(_ScaleraRoughness, _CorneaRoughness, irisMask);
                float3 surfaceNormal = lerp(scaleraNormal, float3(0, 0, 1), irisMask);
                
                // float3 color = EyePhysicallyBasedLighting(eyeData);

                return irisMask;

                half metallic = 1;
                half ao = SAMPLE_TEXTURE2D(_AOMap, sampler_AOMap, i.uv);
                ao = lerp(1, ao, _AO);


                float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                float3 SH = SampleSHPixel(i.vertexSH, i.normalWS);

                float2 screenUV = GetNormalizedScreenSpaceUV(i.positionCS);

                #if defined(_SCREEN_SPACE_OCCLUSION)
                AmbientOcclusionFactor aoFactor;
                aoFactor = GetScreenSpaceAmbientOcclusion(screenUV);
                ao = min(ao,aoFactor.indirectAmbientOcclusion);
                #endif


                //------------------- brdf-----
                float3 diffuseColor = lerp(scaleraMap, 0, metallic);
                float3 specularColor = lerp(float3(0.4, 0.4, 0.4), scaleraMap, metallic);


                return 1;
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