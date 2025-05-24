Shader"Custom/URPWaterHLSL"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.1, 0.3, 0.8, 0.7)
        _AlphaScale ("Overall Alpha Scale", Range(0,1)) = 0.7
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent"
            "IgnoreProjector"="True"
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float _AlphaScale;
            CBUFFER_END

            struct VertexInput
            {
                float4 positionOS : POSITION; // Object space position
                float2 uv : TEXCOORD0; // UV coordinates
                UNITY_VERTEX_INPUT_INSTANCE_ID // For GPU instancing
            };

            struct VertexOutput
            {
                float4 positionCS : SV_POSITION; // Clip space position
                float2 uv : TEXCOORD0;
            };

            VertexOutput vert(VertexInput IN)
            {
                VertexOutput OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(VertexOutput IN) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

                half4 finalColor = _BaseColor;
                finalColor.a *= _AlphaScale;

                return finalColor;
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}