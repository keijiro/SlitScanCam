Shader "Hidden/SlitScanCam"
{
    Properties
    {
        _Buffer0Tex("", 2D) = "black" {}
        _Buffer1Tex("", 2D) = "black" {}
        _Buffer2Tex("", 2D) = "black" {}
        _Buffer3Tex("", 2D) = "black" {}
        _Buffer4Tex("", 2D) = "black" {}
        _Buffer5Tex("", 2D) = "black" {}
        _Buffer6Tex("", 2D) = "black" {}
        _Buffer7Tex("", 2D) = "black" {}
    }

    CGINCLUDE

#include "UnityCG.cginc"

    sampler2D _WebCamTex;
    float2 _Offset;
    float _VFlip;

    sampler2D _Buffer0Tex, _Buffer1Tex, _Buffer2Tex, _Buffer3Tex,
              _Buffer4Tex, _Buffer5Tex, _Buffer6Tex, _Buffer7Tex;
    uint _Index;
    float _Axis;

    void VertexInput(uint vid : SV_VertexID,
                     out float4 pos : SV_Position,
                     out float2 uv : TEXCOORD0)
    {
        float x = vid == 2 || vid > 3;
        float y = vid & 1;

        pos = float4(x, y, 1, 1);
        pos.xy = pos.xy / 2 + _Offset * 2 - 1;
        pos.y *= -1;

        uv = float2(x, lerp(y, 1 - y, _VFlip));
    }

    float4 FragmentInput(float4 pos : SV_Position,
                         float2 uv : TEXCOORD0) : SV_Target
    {
        return tex2D(_WebCamTex, uv);
    }

    void VertexComposite(uint vid : SV_VertexID,
                         out float4 pos : SV_Position,
                         out float2 uv : TEXCOORD0)
    {
        float x = vid == 2 || vid > 3;
        float y = vid & 1;

        pos = float4(x * 2 - 1, y * 2 - 1, 1, 1);
        uv = float2(x, y);
    }

    float3 SampleCombined(uint frame, float2 uv)
    {
        uv.x += frame      & 3;
        uv.y += frame >> 2 & 3;
        uv /= 4;
        uint index = frame >> 4 & 7;
        return index == 0 ? tex2D(_Buffer0Tex, uv).rgb :
               index == 1 ? tex2D(_Buffer1Tex, uv).rgb :
               index == 2 ? tex2D(_Buffer2Tex, uv).rgb :
               index == 3 ? tex2D(_Buffer3Tex, uv).rgb :
               index == 4 ? tex2D(_Buffer4Tex, uv).rgb :
               index == 5 ? tex2D(_Buffer5Tex, uv).rgb :
               index == 6 ? tex2D(_Buffer6Tex, uv).rgb :
                            tex2D(_Buffer7Tex, uv).rgb;
    }

    float4 FragmentComposite(float4 pos : SV_Position,
                             float2 uv : TEXCOORD0) : SV_Target
    {
        float select = lerp(uv.x, uv.y, _Axis) * 0x80;
        uint offset = select;
        float3 p1 = SampleCombined((_Index + offset    ) & 0x7f, uv);
        float3 p2 = SampleCombined((_Index + offset + 1) & 0x7f, uv);
        return float4(lerp(p1, p2, frac(select)), 1);
    }

    float4 FragmentComposite2(float4 pos : SV_Position,
                              float2 uv : TEXCOORD0) : SV_Target
    {
        float3 acc = 0;

        for (uint i = 0; i < 8; i++)
        {
            float hue = i / 8.0;
            float h = hue * 6 - 2;
            float3 rgb = saturate(half3(abs(h - 1) - 1, 2 - abs(h), 2 - abs(h - 2)));

            float3 p = SampleCombined((_Index + 0x80 - i * 8) & 0x7f, uv);
            float lm = Luminance(p);
            lm = saturate((lm - 0.5) * 10 + 0.5);

            acc += rgb * lm / 5;
        }

        return float4(acc, 1);
    }

    ENDCG

    SubShader
    {
        Pass
        {
            Cull off
            ZTest Always
            CGPROGRAM
            #pragma vertex VertexInput
            #pragma fragment FragmentInput
            ENDCG
        }
        Pass
        {
            Cull off
            ZTest Always
            CGPROGRAM
            #pragma vertex VertexComposite
            #pragma fragment FragmentComposite
            ENDCG
        }
        Pass
        {
            Cull off
            ZTest Always
            CGPROGRAM
            #pragma vertex VertexComposite
            #pragma fragment FragmentComposite2
            ENDCG
        }
    }
}
