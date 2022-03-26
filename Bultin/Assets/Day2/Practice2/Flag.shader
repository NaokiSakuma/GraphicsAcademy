Shader "Unlit/Flag"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Speed ("Speed", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 rgb : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                // sinカーブで旗のような表現を行う
                v.vertex.y += sin(v.vertex.x + _Time.y * _Speed);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // 0 ~ 1でClamp
                o.rgb = saturate(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(i.rgb, 1);
            }
            ENDCG
        }
    }
}
