Shader "Hidden/Slitscan"
{
    Properties
    {
        _Buffer1Tex("", 2D) = "black" {}
        _Buffer2Tex("", 2D) = "black" {}
        _Buffer3Tex("", 2D) = "black" {}
        _Buffer4Tex("", 2D) = "black" {}
    }

    CGINCLUDE

    sampler2D _WebCamTex;
    float2 _Offset;

    sampler2D _Buffer1Tex;
    sampler2D _Buffer2Tex;
    sampler2D _Buffer3Tex;
    sampler2D _Buffer4Tex;
    uint _Index;

    void VertexInput(uint vid : SV_VertexID,
                     out float4 pos : SV_Position,
                     out float2 uv : TEXCOORD0)
    {
        float x = vid == 2 || vid > 3;
        float y = vid & 1;

        pos = float4(x, y, 1, 1);
        pos.xy = pos.xy / 2 + _Offset * 2 - 1;
        pos.y =  - pos.y;

        uv = float2(x, y);
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

    float4 FragmentComposite(float4 pos : SV_Position,
                             float2 uv : TEXCOORD0) : SV_Target
    {
        uint frame = ((uint)(uv.y * 64) + _Index) & 0x3f;
        uint index = frame >> 4 & 3;
        float ox = ((frame     ) & 3) / 4.0f;
        float oy = ((frame >> 2) & 3) / 4.0f;

        float2 uv2 = uv / 4 + float2(ox, oy);

        return
            index == 0 ? tex2D(_Buffer1Tex, uv2) :
            index == 1 ? tex2D(_Buffer2Tex, uv2) :
            index == 2 ? tex2D(_Buffer3Tex, uv2) :
                         tex2D(_Buffer4Tex, uv2);
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
