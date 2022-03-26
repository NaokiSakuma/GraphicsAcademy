Shader "Unlit/SpriteAnimationGrid"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [IntRange]_Width ("Width", Range(1, 255)) = 1
        [IntRange]_Height ("Hight", Range(1, 255)) = 1
        _Speed ("Speed", float) = 0.1
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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Width;
            float _Height;
            half _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                // uvが0~1なので、1を何分割しているか
                float2 xy = 1.0f / float2(_Width, _Height);
                // 何番目のgridを出すか
                float index = floor(_Time.y / _Speed % (_Width * _Height));
                o.vertex = UnityObjectToClipPos(v.vertex);
                // indexを元にuvをズラす
                o.uv = TRANSFORM_TEX(v.uv, _MainTex) * xy + float2(index % _Width, floor(index / _Height)) * xy;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return tex2D(_MainTex, i.uv);
            }
            ENDCG
        }
    }
}
