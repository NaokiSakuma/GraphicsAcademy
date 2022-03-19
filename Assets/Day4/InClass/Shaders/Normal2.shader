Shader "Day4/Normal2"
{
    Properties
    {
        [NoScaleOffset] _MainTex("Base (RGB)", 2D) = "white" {}
        [NoScaleOffset][Normal] _NormalMap("Normal map", 2D) = "bump" {}
    }

    SubShader{
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque"}

        CGINCLUDE
        #include "UnityCG.cginc"
        #include "Lighting.cginc"
        #include "AutoLight.cginc"

        sampler2D _MainTex;
        float4 _MainTex_ST;
        sampler2D _NormalMap;
        float4 _NormalMap_ST;

        struct v2f {
            float4 pos      : SV_POSITION; // MVP変換後の頂点座標
            float3 normal   : NORMAL;      // 法線

            float2 uv       : TEXCOORD0;   // UV座標
            float3 tangent  : TEXCOORD1;   // 接ベクトル
            float3 binormal : TEXCOORD2;   // 従法線
            float4 worldPos : TEXCOORD3;   // ワールド座標の頂点座標
            // ライトと影情報
            LIGHTING_COORDS(4, 5)
            float3 ambient  : TEXCOORD6;   // 環境光
        };

        v2f vert(appdata_tan v)
        {
            v2f o = (v2f)0;

            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
            o.worldPos = mul(unity_ObjectToWorld, v.vertex);

            // 接ベクトルと従法線をワールド空間に変換する
            o.normal = UnityObjectToWorldNormal(v.normal);
            o.tangent = normalize(mul(unity_ObjectToWorld, v.tangent.xyz));
            o.binormal = cross(v.normal, v.tangent) * v.tangent.w;
            o.binormal = normalize(mul(unity_ObjectToWorld, o.binormal));

            // ライトと影情報(AutoLight.cginc)
            TRANSFER_VERTEX_TO_FRAGMENT(o);

            // 環境光の設定(unityCG.cgincの実装を参考)
            #if UNITY_SHOULD_SAMPLE_SH
                #if defined(VERTEXLIGHT_ON)
                o.ambient = Shade4PointLights(
                    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                    unity_LightColor[0].rgb, unity_LightColor[1].rgb,
                    unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                    unity_4LightAtten0, o.worldPos, o.normal
                );
                #endif
                o.ambient += max(0, ShadeSH9(float4(o.normal, 1)));
            #else
                o.ambient = 0;
            #endif

            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            //タンジェントスペースの変換行列を求め、法線マップをワールドスペースに変換
            float3x3 tangentSpaceTransform = float3x3(i.tangent, i.binormal, i.normal);
            // 転置行列を求めて列優先から行優先に変換
            tangentSpaceTransform = transpose(tangentSpaceTransform);
            float3 normalLocal = UnpackNormal(tex2D(_NormalMap, i.uv));
            float3 normalWorld = normalize(mul(tangentSpaceTransform, normalLocal));

            // ディレクショナルライト以外の時は距離による減衰を考慮
            float3 lightDir = normalize(_WorldSpaceLightPos0.w == 0 ?
                                        _WorldSpaceLightPos0.xyz :
                                        _WorldSpaceLightPos0.xyz - i.worldPos);

            // ライトの減衰を求める(AutoLight.cginc)
            // 事前準備として、頂点シェーダーでTRANSFER_VERTEX_TO_FRAGMENT()を呼ぶ
            float attenuation = LIGHT_ATTENUATION(i);

            // 拡散反射を求める
            float3 diff = max(0, dot(normalWorld, lightDir)) * _LightColor0 * attenuation;

            // メインテクスチャからカラー値をサンプリング
            fixed4 color = tex2D(_MainTex, i.uv);
            color.rgb *= diff;
            color.rgb += i.ambient;
            return color;
        }
        ENDCG

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase 

            ENDCG
        }

        Pass
        {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd

            ENDCG
        }
    }
}