Shader "Day4/Normal1"
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

            struct v2f {
                float4 pos      : SV_POSITION; // MVP変換後の頂点座標
                float3 normal   : NORMAL;      // 法線

                float2 uv       : TEXCOORD0;   // UV座標
                float3 tangent  : TEXCOORD1;   // 接ベクトル
                float3 biNormal : TEXCOORD2;   // 従法線
            };

            // 頂点シェーダー(タンジェントスペースの接ベクトルを含む定義済み構造体を使用)
            v2f vert(appdata_tan v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv  = v.texcoord;

                // 接ベクトルと従法線をワールド空間に変換する
                // unity_ObjectToWorld: モデル行列
                o.normal   = UnityObjectToWorldNormal(v.normal);
                o.tangent  = normalize(mul(unity_ObjectToWorld, v.tangent.xyz));
                o.biNormal = cross(v.normal, v.tangent) * v.tangent.w;
                o.biNormal = normalize(mul(unity_ObjectToWorld, o.biNormal));

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // ディフューズマップをサンプリング
                float4 diffuseMap = tex2D(_MainTex, i.uv);

                float3 normal = i.normal;

                // step-5 法線マップからタンジェントスペースの法線をサンプリングする
                float3 localNormal = UnpackNormal(tex2D(_NormalMap, i.uv));

                // タンジェントスペースの法線を0～1の範囲から-1～1の範囲に復元する
                // localNormal = (localNormal - 0.5f) * 2.0f;

                // step-6 タンジェントスペースの法線をワールドスペースに変換する
                normal = i.tangent  * localNormal.x
                       + i.biNormal * localNormal.y
                       +     normal * localNormal.z;

                // 環境光を求める
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                // 拡散反射光を計算する
                float3 lig = 0.0f;
                lig += max(0.0f, dot(normal, _WorldSpaceLightPos0.xyz)) * _LightColor0;
                lig += ambient;

                float4 finalColor = diffuseMap;
                finalColor.xyz *= lig;

                return finalColor;

            }
            ENDCG
        }
    }
}

