Shader "Day4/NormalCubemap"
{
    Properties
    {
        [NoScaleOffset] _MainTex("Base (RGB)", 2D) = "white" {}
        [NoScaleOffset] [Normal] _NormalMap("Normal map", 2D) = "bump" {}
    }

    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque"}

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            sampler2D _NormalMap;

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float3 tangent : TEXCOORD1;
                float3 biNormal : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
            };

            v2f vert(appdata_tan v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv  = v.texcoord;

                o.normal   = UnityObjectToWorldNormal(v.normal);
                o.tangent  = normalize(mul(unity_ObjectToWorld, v.tangent.xyz));
                o.biNormal = cross(v.normal, v.tangent) * v.tangent.w;
                o.biNormal = normalize(mul(unity_ObjectToWorld, o.biNormal));
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 diffuseMap = tex2D(_MainTex, i.uv);
                float3 normal = i.normal;

                float3 localNormal = UnpackNormal(tex2D(_NormalMap, i.uv));

                normal = i.tangent  * localNormal.x
                       + i.biNormal * localNormal.y
                       +     normal * localNormal.z;

                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                float3 lig = 0.0f;
                lig += max(0.0f, dot(normal, _WorldSpaceLightPos0.xyz)) * _LightColor0;
                lig += ambient;

                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 reflDir = reflect(-viewDir, i.normal);
                fixed4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflDir);
                half3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);

                fixed4 finalColor = fixed4(
                    diffuseMap.xyz * lig * skyColor,
                    diffuseMap.a);

                return finalColor;

            }
            ENDCG
        }
    }
}
