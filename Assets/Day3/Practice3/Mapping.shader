Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SpecularTex ("Specular Texture", 2D) = "white" {}
        _AOTex ("AO Texture", 2D) = "white" {}
        _SpecularPow ("Speclar Pow", float) = 5
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
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                half3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                LIGHTING_COORDS(3, 4)
                half3 ambient : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _SpecularTex;
            float4 _SpecularTex_ST;
            sampler2D _AOTex;
            float4 _AOTex_ST;
            half _SpecularPow;
            half4 _LightColor0;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos.xyz);
                o.normal = UnityObjectToWorldNormal(v.normal);

                #if UNITY_SHOULD_SAMPLE_SH
                    #if defined(VEXTEXLIGHT_ON)
                        o.ambient = Shade4PointLights(
                            unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                            unity_LightColor[0].rbg, unity_LightColor[1].rbg, unity_LightColor[2].rbg, unity_LightColor[3].rbg,
                            unity_LightAtten0, o.worldPos, o.normal);
                    #endif
                    o.ambient += saturete(ShadeSH9(float4(o.normal, 1)));
                #else
                    o.ambient = 0;
                #endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                // 拡散反射
                float diffuse = saturate(dot(i.normal, _WorldSpaceLightPos0.xyz));
                // 鏡面反射
                float specular = pow(saturate(dot(reflect(-_WorldSpaceLightPos0.xyz, i.normal), i.viewDir)), _SpecularPow);
                fixed4 speclarTex = tex2D(_SpecularTex, i.uv);
                float resultSpeclar = specular * speclarTex.r;
                // アンビエントオクルージョン
                UNITY_LIGHT_ATTENUATION(attenuation, i, i.normal);
                fixed4 ambientTex = tex2D(_AOTex, i.uv);
                float ambientCol = ambientTex ;

                fixed4 result = fixed4(col.rgb * (resultSpeclar + diffuse + ambientCol), col.a);
                return result;
            }
            ENDCG
        }
    }
}
