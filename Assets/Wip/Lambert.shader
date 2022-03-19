Shader "Day3/Lambert"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex   : POSITION;
                float3 normal   : NORMAL;
                float2 uv       : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                float3 normal   : NORMAL;
                float2 uv       : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);  // MVP変換
                // step-6 頂点法線をピクセルシェーダーに渡す
                o.normal = UnityObjectToWorldNormal(v.normal); // 法線を回転させる
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // step-2 ディレクションライトのデータを作成する
                float3 ligDirection = normalize(_WorldSpaceLightPos0.xyz);

                // step-7 ピクセルの法線とライトの方向の内積を計算する
                float t = dot(i.normal, ligDirection);

                // ディレクショナルライト(_WorldSpaceLightPos0)は
                // ワールド空間座標になっています。
                // 一方、DirectXのサンプルコードはモデル空間のままのため
                // その補正をするために「内積の結果に-1を乗算する」を
                // していると予想。ここでは不要なためコメントにします。
                // 内積の結果に-1を乗算する
                //t *= -1.0f;

                // step-8 内積の結果が0以下なら0にする
                if (t < 0.0f)
                {
                    t = 0.0f;
                }
                // このif文の代わりに、t = max(0.0f, t); または t = saturate(t); も利用可能

                // step-9 ピクセルが受けているライトの光を求める
                fixed3 ligColor = _LightColor0.xyz; // #include "Lighting.cginc" にて定義
                fixed3 diffuseLig = ligColor * t;

                float4 finalColor = tex2D(_MainTex, i.uv);

                // step-10 最終出力カラーに光を乗算する
                finalColor.xyz *= diffuseLig;

                return finalColor;
            }
            ENDCG
        }
    }
}
