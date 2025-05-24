Shader "Custom/2D/UnlitSprite"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HighlightTex ("Highlight Texture", 2D) = "white" {}
        _DistortionMap ("Distortion Map", 2D) = "white" {}
        _HighlightVisibilityMap ("Highlight Visibility Map", 2D) = "white" {}
        _BaseWaterColor ("Base Water Color", Color) = (1,1,1,1)
        _HighlightColor ("Highlight Color", Color) = (1,1,1,1)
        _HighlightIntensity ("Highlight Intensity", Range(0,20)) = 1.5
        _HighlightScrollSpeed ("Scroll Speed", Range(0.1,2)) = 0.1
        _DistortionScrollSpeedX ("Distortion Scroll Speed X", Range(0.1,2)) = 0.1
        _DistortionScrollSpeedY ("Distortion Scroll Speed Y", Range(0.1,2)) = 0.1
        _DistortionStrength ("Distortion Strength", Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "CanUseSpriteAtlas" = "True"
            "RenderPipeline" = "UniversalRenderPipeline"
        }

        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZWrite Off
        Lighting Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct VertexInput
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct VertexOutput
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 highlightUV : TEXCOORD1;
                float2 highlightVisibilityUV : TEXCOORD2;
                float2 distortionUV : TEXCOORD3;
                float4 color : COLOR;
            };

            TEXTURE2D(_MainTex);
            TEXTURE2D(_HighlightTex);
            TEXTURE2D(_DistortionMap);
            TEXTURE2D(_HighlightVisibilityMap);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_HighlightTex);
            SAMPLER(sampler_DistortionMap);
            SAMPLER(sampler_HighlightVisibilityMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _HighlightTex_ST;
                float4 _DistortionMap_ST;
                float4 _HighlightVisibilityMap_ST;
                half4 _BaseWaterColor;
                half4 _HighlightColor;
                float _HighlightIntensity;
                float _HighlightScrollSpeed;
                float _DistortionScrollSpeedX;
                float _DistortionScrollSpeedY;
                float _DistortionStrength;
            CBUFFER_END

            VertexOutput vert(VertexInput i)
            {
                VertexOutput o;
                
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = TRANSFORM_TEX(i.uv, _MainTex);
                o.highlightUV = TRANSFORM_TEX(i.uv, _HighlightTex);
                o.highlightVisibilityUV = TRANSFORM_TEX(i.uv, _HighlightVisibilityMap);
                o.distortionUV = TRANSFORM_TEX(i.uv, _DistortionMap);
                o.color = i.color * _BaseWaterColor;
                
                return o;
            }

            half4 frag(VertexOutput i) : SV_Target
            {
                // 1. Sample the main sprite texture (for shape/alpha mask)
                half4 mainSpriteTexture = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                // Optional: Discard pixels outside the main sprite's alpha mask early
                // This is good if _MainTex has hard edges.
                // For smooth edges, the final alpha calculation will handle it.
                if (mainSpriteTexture.a < 0.01h) { discard; }


                float2 distortionUV = i.distortionUV;
                distortionUV.x += _DistortionScrollSpeedX * _Time.y;
                distortionUV.y += _DistortionScrollSpeedY * _Time.y;
                distortionUV = frac(distortionUV);

                float2 distortionOffset = SAMPLE_TEXTURE2D(_DistortionMap, sampler_DistortionMap, distortionUV).rg;
                distortionOffset = (distortionOffset * 2.0 - 1.0) * _DistortionStrength;

                half2 scrolledUV = i.highlightUV;
                scrolledUV.x += _Time.y * _HighlightScrollSpeed;
                scrolledUV += distortionOffset;
                scrolledUV = frac(scrolledUV);
                half4 highlightTex = SAMPLE_TEXTURE2D(_HighlightTex, sampler_HighlightTex, scrolledUV);
                half4 finalColor = _BaseWaterColor;

                // Apply highlight visibility map
                float2 highlightVisibilityUV = i.highlightVisibilityUV;
                float2 highlightStrength = SAMPLE_TEXTURE2D(_HighlightVisibilityMap, sampler_HighlightVisibilityMap, highlightVisibilityUV).rg;
                float highlightIntensity = highlightStrength.r * _HighlightIntensity;
                finalColor.rgb += highlightTex.rgb * _HighlightColor.rgb * highlightIntensity;

                finalColor.rgb = saturate(finalColor.rgb);

                finalColor.a = mainSpriteTexture.a * _BaseWaterColor.a * i.color.a;
                
                return finalColor;
            }
            ENDHLSL
        }
    }
}