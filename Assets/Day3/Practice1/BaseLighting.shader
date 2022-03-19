Shader "Day3/Practice1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SpecularPow ("Speclar Pow", float) = 5
        _AmbientColor ("Ambient Color", Color) = (0, 0, 0, 1)
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
                float3 viewDir : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            // ライトの色を取得する
            half4 _LightColor0;
            half _SpecularPow;
            fixed4 _AmbientColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(ShadeSH9(float4(i.normal, 1)), 1);
                return fixed4(UNITY_LIGHTMODEL_AMBIENT.xyz, 1);

                fixed4 texCol = tex2D(_MainTex, i.uv);

                // 拡散反射
                float diffuse = saturate(dot(i.normal, _WorldSpaceLightPos0.xyz));

                // 鏡面反射
                float3 reflectVec = reflect(-_WorldSpaceLightPos0.xyz, i.normal);
                float specular = pow(saturate(dot(reflectVec, i.viewDir)), _SpecularPow);

                return texCol * (diffuse + specular) * _LightColor0 + _AmbientColor;
            }
            ENDCG
        }
    }
}
