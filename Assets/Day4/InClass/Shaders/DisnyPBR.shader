Shader "Day4/PBRShader"
{
    Properties
    {
        [NoScaleOffset] _MainTex("Base (RGB)", 2D) = "white" {}
        [NoScaleOffset][Normal] _NormalMap("Normal map", 2D) = "bump" {}
        [NoScaleOffset] _MetallicMap("Metallic", 2D) = "white" {} // メタリックマップ
        [NoScaleOffset] _OcclusionMap("Occlusion Map", 2D) = "white" {} // AOマップ

    }

    SubShader{
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque"}

        CGINCLUDE
        #include "UnityCG.cginc"
        #include "Lighting.cginc"
        #include "AutoLight.cginc"

        const static float PI = 3.141592;

        sampler2D _MainTex;
        float4 _MainTex_ST;
        sampler2D _NormalMap;
        float4 _NormalMap_ST;
        sampler2D _MetallicMap;
        float4 _MetallicMap_ST;
        sampler2D _OcclusionMap;
        float4 _OcclusionMap_ST;

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

        float3 GetNormal(float3 normal, float3 tangent, float3 biNormal, float2 uv)
        {
            float3 binSpaceNormal = UnpackNormal(tex2D(_NormalMap, uv));
            // binSpaceNormal = (binSpaceNormal * 2.0f) - 1.0f;

            float3 newNormal = tangent * binSpaceNormal.x + biNormal * binSpaceNormal.y + normal * binSpaceNormal.z;

            return newNormal;
        }

        // ベックマン分布を計算する
        float Beckmann(float m, float t)
        {
            float t2 = t * t;
            float t4 = t * t * t * t;
            float m2 = m * m;
            float D = 1.0f / (4.0f * m2 * t4);
            D *= exp((-1.0f / m2) * (1.0f - t2) / t2);
            return D;
        }

        // フレネルを計算。Schlick近似を使用
        float SpcFresnel(float f0, float u)
        {
            // from Schlick
            return f0 + (1 - f0) * pow(1 - u, 5);
        }

        /// <summary>
        /// Cook-Torranceモデルの鏡面反射を計算
        /// </summary>
        /// <param name="L">光源に向かうベクトル</param>
        /// <param name="V">視点に向かうベクトル</param>
        /// <param name="N">法線ベクトル</param>
        /// <param name="metallic">金属度</param>
        float CookTorranceSpecular(float3 L, float3 V, float3 N, float metallic)
        {
            float microfacet = 0.76f;

            // 金属度を垂直入射の時のフレネル反射率として扱う
            // 金属度が高いほどフレネル反射は大きくなる
            float f0 = metallic;

            // ライトに向かうベクトルと視線に向かうベクトルのハーフベクトルを求める
            float3 H = normalize(L + V);

            // 各種ベクトルがどれくらい似ているかを内積を利用して求める
            float NdotH = saturate(dot(N, H));
            float VdotH = saturate(dot(V, H));
            float NdotL = saturate(dot(N, L));
            float NdotV = saturate(dot(N, V));

            // D項をベックマン分布を用いて計算する
            float D = Beckmann(microfacet, NdotH);

            // F項をSchlick近似を用いて計算する
            float F = SpcFresnel(f0, VdotH);

            // G項を求める
            float G = min(1.0f, min(2 * NdotH * NdotV / VdotH, 2 * NdotH * NdotL / VdotH));

            // m項を求める
            float m = PI * NdotV * NdotH;

            // ここまで求めた、値を利用して、Cook-Torranceモデルの鏡面反射を求める
            return max(F * D * G / m, 0.0);
        }

        /// <summary>
        /// フレネル反射を考慮した拡散反射を計算
        /// </summary>
        /// <remark>
        /// この関数はフレネル反射を考慮した拡散反射率を計算します
        /// フレネル反射は、光が物体の表面で反射する現象のとこで、鏡面反射の強さになります
        /// 一方拡散反射は、光が物体の内部に入って、内部錯乱を起こして、拡散して反射してきた光のことです
        /// つまりフレネル反射が弱いときには、拡散反射が大きくなり、フレネル反射が強いときは、拡散反射が小さくなります
        ///
        /// </remark>
        /// <param name="N">法線</param>
        /// <param name="L">光源に向かうベクトル。光の方向と逆向きのベクトル。</param>
        /// <param name="V">視線に向かうベクトル。</param>
        /// <param name="roughness">粗さ。0～1の範囲。</param>
        float CalcDiffuseFromFresnel(float3 N, float3 L, float3 V)
        {
            // step-1 ディズニーベースのフレネル反射による拡散反射を真面目に実装する。
            // 光源に向かうベクトルと視線に向かうベクトルのハーフベクトルを求める
            float3 H = normalize(L + V);

            // 粗さは0.5で固定。
            float roughness = 0.5f;

            float energyBias = lerp(0.0f, 0.5f, roughness);
            float energyFactor = lerp(1.0, 1.0 / 1.51, roughness);

            // 光源に向かうベクトルとハーフベクトルがどれだけ似ているかを内積で求める
            float dotLH = saturate(dot(L, H));

            // 光源に向かうベクトルとハーフベクトル、
            // 光が平行に入射したときの拡散反射量を求めている
            float Fd90 = energyBias + 2.0 * dotLH * dotLH * roughness;

            // 法線と光源に向かうベクトルwを利用して拡散反射率を求める
            float dotNL = saturate(dot(N, L));
            float FL = (1 + (Fd90 - 1) * pow(1 - dotNL, 5));

            // 法線と視点に向かうベクトルを利用して拡散反射率を求める
            float dotNV = saturate(dot(N, V));
            float FV = (1 + (Fd90 - 1) * pow(1 - dotNV, 5));

            // 法線と光源への方向に依存する拡散反射率と、法線と視点ベクトルに依存する拡散反射率を
            // 乗算して最終的な拡散反射率を求めている。PIで除算しているのは正規化を行うため
            return (FL * FV * energyFactor);
        }

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
            // 法線を計算
            float3 normal = GetNormal(i.normal, i.tangent, i.binormal, i.uv);

            // アルベドカラー、スペキュラカラー、金属度、滑らかさをサンプリングする。
            // アルベドカラー（拡散反射光）
            float4 albedoColor = tex2D(_MainTex, i.uv);

            // スペキュラカラーはアルベドカラーと同じにする。
            float3 specColor = albedoColor;

            // 金属度
            float metallic = tex2D(_MetallicMap, i.uv).r;

            // 滑らかさ
            float smooth = tex2D(_MetallicMap, i.uv).a;

            float3 light = normalize(_WorldSpaceLightPos0.w == 0 ?
                _WorldSpaceLightPos0.xyz :
                _WorldSpaceLightPos0.xyz - i.worldPos);

            // 視線に向かって伸びるベクトルを計算する
            float3 toEye = normalize(_WorldSpaceCameraPos - i.worldPos);

            float3 lig = 0;
            // シンプルなディズニーベースの拡散反射を実装する。
            // フレネル反射を考慮した拡散反射を計算
            float diffuseFromFresnel = CalcDiffuseFromFresnel(
                normal, light, toEye);

            // 正規化Lambert拡散反射を求める
            float NdotL = saturate(dot(normal, light));
            float3 lambertDiffuse = _LightColor0 * NdotL / PI;

            // ライトの減衰を求める(AutoLight.cginc)
            // 事前準備として、頂点シェーダーでTRANSFER_VERTEX_TO_FRAGMENT()を呼ぶ
            float attenuation = LIGHT_ATTENUATION(i);

            // 最終的な拡散反射光を計算する
            float3 diffuse = albedoColor * diffuseFromFresnel * lambertDiffuse * attenuation;

            // Cook-Torranceモデルを利用した鏡面反射率を計算する
            // Cook-Torranceモデルの鏡面反射率を計算する
            float3 spec = CookTorranceSpecular(
                light, toEye, normal, smooth)
                * _LightColor0;

            // 金属度が高ければ、鏡面反射はスペキュラカラー、低ければ白
            // スペキュラカラーの強さを鏡面反射率として扱う
            spec *= lerp(float3(1.0f, 1.0f, 1.0f), specColor, metallic);

            // 滑らかさを使って、拡散反射光と鏡面反射光を合成する
            // 滑らかさが高ければ、拡散反射は弱くなる
            lig += diffuse * (1.0f - smooth) + spec;

            // 環境光による底上げ
            float ambientPower = tex2D(_OcclusionMap, i.uv);
            lig += i.ambient * albedoColor * ambientPower;

            float4 finalColor = 1.0f;
            finalColor.xyz = lig;
            return finalColor;
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