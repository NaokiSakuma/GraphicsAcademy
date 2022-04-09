Shader "SnowScene/FallSnow"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "Renderpipeline" = "UniversalPipeline"
        }

        ZWrite Off
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #define UNITY_MATRIX_TEXTURE0 float4x4(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)

            CBUFFER_START(UnityPerMaterial)
                sampler2D _MainTex;
                float4x4 _PrevInvMatrix;
                float3 _TargetPosition;
                float _Range;
                float _RangeReverse;
                float _Size;
                float3 _MoveTotal;
                float3 _CamUp;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float cameraLength : TEXCOORD1;
            };

            float2 MultiplyUV(float4x4 mat, float2 inUV)
            {
                float4 temp = float4(inUV.x, inUV.y, 0, 0);
                temp = mul(mat, temp);
                return temp.xy;
            }

            float3 ShakeXZSnow(float3 moveValue)
            {
                float3 shake = float3(
                        sin(moveValue.x * 0.2) * sin(moveValue.y * 0.3) * sin(moveValue.x * 0.9) * sin(moveValue.y * 0.8),
                        0,
                        sin(moveValue.x * 0.1) * sin(moveValue.y * 0.2) * sin(moveValue.x * 0.8) * sin(moveValue.y * 1.2)
                    );

                return moveValue + shake;
            }

            Varyings vert(Attributes IN)
            {
                float3 moveValue = IN.positionOS + _MoveTotal;
                float3 repeat = floor(((_TargetPosition - moveValue) * _RangeReverse + 1) * 0.5f);
                repeat *= _Range * 2;
                moveValue += repeat;

                float3 diff = _CamUp * _Size;
                float3 snowPos = ShakeXZSnow(moveValue);

                float3 eyeVector = TransformWorldToObject(float4(snowPos, 0));
                float3 sideVector = normalize(cross(eyeVector, diff));
                snowPos += (IN.uv.x - 0.5f) * sideVector * _Size;
                snowPos += (IN.uv.y - 0.5f) * diff;

                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(snowPos);
                OUT.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, IN.uv);
                float3 worldPos = mul(unity_ObjectToWorld, snowPos).xyz;
                OUT.cameraLength = length(_WorldSpaceCameraPos - worldPos) * 0.8;
                return OUT;
            }

            half4 frag(Varyings IN) :SV_TARGET
            {
                #define _MaxMipMapNum 5
                return tex2Dlod(_MainTex, float4(IN.uv, 0, _MaxMipMapNum - IN.cameraLength));
            }
            ENDHLSL
        }
    }
}
