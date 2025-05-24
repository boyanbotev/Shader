Shader "Custom/SpriteSimpleUnlit"
{
    Properties
    {
        _ScrollSpeed ("Scroll Speed", Range(0.1,2)) = 0.1
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0.1, 0.3, 0.8, 0.7)
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "IgnoreProjector"="True"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        LOD 100

        Cull Off
        Lighting Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct VertexInput
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 color : COLOR;
            };

            struct VertexOutput
            {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                float4 color : COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _ScrollSpeed;
            float4 _Color;

            VertexOutput vert(VertexInput i)
            {
                VertexOutput o;
                o.vertex = UnityObjectToClipPos(i.vertex);
                o.texcoord = TRANSFORM_TEX(i.texcoord, _MainTex);
                o.color = _Color;
                return o;
            }

            fixed4 frag(VertexOutput i) : SV_Target
            {
                float2 scrolledUV;
                float2 originalUV = i.texcoord;
    
                scrolledUV.x = originalUV.x + _ScrollSpeed * _Time.y;
                scrolledUV.y = originalUV.y;
    
                //scrolledUV = frac(scrolledUV);
                fixed4 texColor = tex2D(_MainTex, scrolledUV);
    
                // make all pixels with colours darker, transparent
                if ((texColor.r + texColor.g + texColor.b) < 0.5)
                {
                    discard;
                }
    
                fixed4 finalColor = texColor * _Color;
                
                return finalColor;
            }
            ENDCG
        }
    }
    Fallback "Sprites/Default"
}