Shader "Hidden/SlitScanCam"
{
    Properties
    {
        _BufferTex("", 2DArray) = "" {}
    }

    CGINCLUDE

    #include "UnityCG.cginc"

    #define RESOLUTION 256

    UNITY_DECLARE_TEX2DARRAY(_BufferTex);
    float _VFlip;
    float _Axis;
    uint _Frame;

    float3 GetHistory(float2 uv, uint offset)
    {
        uint i = (_Frame + RESOLUTION - offset) & (RESOLUTION - 1);
        uv.y = lerp(uv.y, 1 - uv.y, _VFlip);
        return UNITY_SAMPLE_TEX2DARRAY(_BufferTex, float3(uv, i)).rgb;
    }

    void Vertex(uint vid : SV_VertexID,
                out float4 pos : SV_Position,
                out float2 uv : TEXCOORD0)
    {
        float x = vid == 2 || vid > 3;
        float y = vid & 1;
        pos = float4(x * 2 - 1, y * 2 - 1, 1, 1);
        uv = float2(x, y);
    }

    float4 FragmentSlitScan(float4 pos : SV_Position,
                            float2 uv : TEXCOORD0) : SV_Target
    {
        float delay = lerp(uv.x, 1 - uv.y, _Axis) * (RESOLUTION - 2);
        uint offset = (uint)delay;
        float3 p1 = GetHistory(uv, offset + 0);
        float3 p2 = GetHistory(uv, offset + 1);
        return float4(lerp(p1, p2, frac(delay)), 1);
    }

    float4 FragmentDelay(float4 pos : SV_Position,
                         float2 uv : TEXCOORD0) : SV_Target
    {
        float3 acc = 0;

        for (uint i = 0; i < 8; i++)
        {
            // Source with monochrome + contrast
            float3 c = GetHistory(uv, i * 8);

            // Hue
            float h = i / 8.0 * 6 - 2;
            c *= saturate(float3(abs(h - 1) - 1, 2 - abs(h), 2 - abs(h - 2)));

            // Accumulation
            acc += c / 4;
        }

        return float4(acc, 1);
    }

    ENDCG

    SubShader
    {
        Pass
        {
            Cull off ZTest Always
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment FragmentSlitScan
            ENDCG
        }
        Pass
        {
            Cull off ZTest Always
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment FragmentDelay
            ENDCG
        }
    }
}
