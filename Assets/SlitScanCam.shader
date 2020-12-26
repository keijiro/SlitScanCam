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

    sampler2D _WebCamTex;
    float2 _Offset;
    float _VFlip;

    sampler2D _Buffer0Tex, _Buffer1Tex, _Buffer2Tex, _Buffer3Tex,
              _Buffer4Tex, _Buffer5Tex, _Buffer6Tex, _Buffer7Tex;
    uint _Index;

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

    float3 SampleCombined(uint offset, float2 uv)
    {
        uint frame = ((uint)(uv.y * 0x80) + offset) & 0x7f;
        uint index = frame >> 4 & 7;
        float ox = ((frame     ) & 3) / 4.0f;
        float oy = ((frame >> 2) & 3) / 4.0f;

        float2 uv2 = uv / 4 + float2(ox, oy);

        return
            index == 0 ? tex2D(_Buffer0Tex, uv2).rgb :
            index == 1 ? tex2D(_Buffer1Tex, uv2).rgb :
            index == 2 ? tex2D(_Buffer2Tex, uv2).rgb :
            index == 3 ? tex2D(_Buffer3Tex, uv2).rgb :
            index == 4 ? tex2D(_Buffer4Tex, uv2).rgb :
            index == 5 ? tex2D(_Buffer5Tex, uv2).rgb :
            index == 6 ? tex2D(_Buffer6Tex, uv2).rgb :
                         tex2D(_Buffer7Tex, uv2).rgb;
    }

    float4 FragmentComposite(float4 pos : SV_Position,
                             float2 uv : TEXCOORD0) : SV_Target
    {
        float3 p1 = SampleCombined(_Index    , uv);
        float3 p2 = SampleCombined(_Index + 1, uv);
        float blend = frac(uv.y * 0x80);
        return float4(lerp(p1, p2, blend), 1);
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
    }
}
