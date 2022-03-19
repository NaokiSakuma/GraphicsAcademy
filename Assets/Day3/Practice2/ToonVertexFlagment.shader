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
        Tags { "RenderType"="Opaque" }
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            // #include "Lighting.cginc"
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
                half3 ambient : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                LIGHTING_COORDS(3, 4)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            sampler2D _Ramp;
            half4 _LightColor0;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

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
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                half NdotL = saturate(dot(i.normal, _WorldSpaceLightPos0.xyz) * 0.5 + 0.5);
                fixed3 ramp = tex2D(_Ramp, NdotL).rgb;

                UNITY_LIGHT_ATTENUATION(attenuation, i, i.normal);
                half3 diff = saturate(dot(i.normal, _WorldSpaceLightPos0.xyz)) * _LightColor0 * attenuation ;
                col.rbg *= diff + i.ambient * ramp;
                return col;
            }
            ENDCG
        }
    }
}
