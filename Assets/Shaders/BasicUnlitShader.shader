Shader"Example/URPUnlitShaderBasic"
{

    Properties
    {
        _RippleFrequency ("Ripple Frequency", Range(1, 200)) = 10
        _RippleSpeed ("Ripple Speed", Range(0.1, 40)) = 2
        _RippleStrength ("Ripple Strength", Range(0, 1)) = 0.2
        _RippleOriginY ("Ripple Origin Y (UV)", Range(0,1)) = 0.5

        [Toggle(_USE_MULTIPLICATION)] _MultiplyRipples ("Multiply Ripples?", Float) = 0

        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _USE_MULTIPLICATION

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"            

            CBUFFER_START(UnityPerMaterial)
                float _RippleFrequency;
                float _RippleSpeed;
                float _RippleStrength;
                float _RippleOriginY;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            struct VertexInput
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct VertexOutput
            {               
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            VertexOutput vert(VertexInput IN)
            {             
                VertexOutput OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
    
                return OUT;
            }
          
            half4 frag(VertexOutput IN) : SV_Target
            {
                half4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                float dist = abs(IN.uv.y - _RippleOriginY);

                half rippleWave = sin(dist * _RippleFrequency - _Time.y * _RippleSpeed);
                rippleWave = (rippleWave + 1.0h) * 0.5h;
    
                half ripple2 = sin(dist * _RippleFrequency * 0.34h - _Time.y * _RippleSpeed);
                ripple2 = (ripple2 + 1.0h) * 0.5h;
   
                half combinedRipple;

                #if _USE_MULTIPLICATION
                    combinedRipple = rippleWave * ripple2;
                #else
                    combinedRipple = (rippleWave + ripple2) * 0.5h;
                #endif
                
                half rippleFactor = lerp(1.0h, combinedRipple, _RippleStrength);
                
                half3 finalColor = baseColor.rgb * rippleFactor;
                return half4(finalColor, baseColor.a);
            }

            ENDHLSL
        }
    }
}