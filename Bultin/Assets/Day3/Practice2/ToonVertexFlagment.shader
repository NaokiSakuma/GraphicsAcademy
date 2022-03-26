Shader "Day3/ToonVertexFlagment"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Main Color", Color) = (0.5, 0.5, 0.5, 1)
        _Ramp ("Toon Ramp (RGB)", 2D) = "gray" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                half3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                half3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                LIGHTING_COORDS(2, 3)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            sampler2D _Ramp;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 texCol = tex2D(_MainTex, i.uv) * _Color;

                half NdotL = saturate(dot(i.normal, _WorldSpaceLightPos0.xyz) * 0.5 + 0.5);
                fixed3 ramp = tex2D(_Ramp, NdotL).rgb;

                float3 ambient = ShadeSH9(float4(i.normal, 1));

                UNITY_LIGHT_ATTENUATION(atten, i, i.normal);
                float3 lightCol = ambient + _LightColor0.rgb * ramp * atten * 2;

                fixed4 col = fixed4(texCol.rgb * lightCol, texCol.a);

                return col;
            }
            ENDCG
        }
    }
}
