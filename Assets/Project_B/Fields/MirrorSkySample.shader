Shader "ProjectB/MirrorSkySample"
{
    Properties
    {
        [NoScaleOffset] _CubeTex("Sky Texture", Cube) = "grey" {}
		_Color ("Tint Color", Color) = (1,1,1,1)
        _Epsilon("Epsilon", Float) = 0.0
        [MaterialToggle] _Reverse("Reverse UpDown", Int) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Background" "Queue"="Background" "PreviewType"="Skybox" }
        Cull Off ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ USE_MIRROR

            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 texcoord : TEXCOORD0;
            };

            samplerCUBE _CubeTex;
			half4 _Color;
            int _Reverse;
			float _Epsilon;

            v2f vert (appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = v.vertex.xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 uv = i.texcoord;
                uv.y = (abs(uv.y) - _Epsilon) * -(_Reverse * 2 - 1);
                half4 tex = texCUBE(_CubeTex, uv);
                half3 c = tex * _Color.rgb;
                return half4(c, 1.0);
            }
            ENDCG
        }
    }
}
