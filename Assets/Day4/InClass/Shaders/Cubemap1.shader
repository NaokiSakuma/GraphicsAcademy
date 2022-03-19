Shader "Day4/Cubemap1"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal  : NORMAL;
                float3 uv      : TEXCOORD0;
            };

            struct v2f {
                float4 pos      : SV_POSITION;
                float3 uv       : TEXCOORD0;
                float3 posWorld : TEXCOORD1;
                float3 normal   : TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                i.normal = normalize(i.normal);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.posWorld);
                // 視点からのベクトルと法線から反射方向のベクトルを計算する
                float3 reflDir = reflect(-viewDir, i.normal);

                // 反射方向のベクトルからSkyboxの色を取得する
                fixed4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflDir);
                // キューブマップデータを実際のカラーにデコードします
                half3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);

                return fixed4(skyColor.rgb, 1);
            }
            ENDCG
        }
    }
}
