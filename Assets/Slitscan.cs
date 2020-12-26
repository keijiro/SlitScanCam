using UnityEngine;

public class Slitscan : MonoBehaviour
{
    [SerializeField] Shader _shader = null;

    WebCamTexture _webcam;
    Material _material;
    RenderTexture[] _buffers;

    RenderTexture AllocateBuffer()
    {
        var rt = new RenderTexture(4096, 4096, 0, RenderTextureFormat.RGB565);
        rt.Create();
        return rt;
    }

    void Start()
    {
        _webcam = new WebCamTexture();
        _webcam.Play();

        _material = new Material(_shader);

        _buffers = new [] { AllocateBuffer(), AllocateBuffer(),
                            AllocateBuffer(), AllocateBuffer() };
    }

    void OnPostRender()
    {
        var frame = Time.frameCount;
        var index = frame >> 4 & 3;
        var ox = ((frame     ) & 3) / 4.0f;
        var oy = ((frame >> 2) & 3) / 4.0f;

        var ac = RenderTexture.active;

        RenderTexture.active = _buffers[index];
        _material.SetVector("_Offset", new Vector2(ox, oy));
        _material.SetTexture("_WebCamTex", _webcam);
        _material.SetPass(0);
        Graphics.DrawProceduralNow(MeshTopology.Triangles, 6, 3);

        RenderTexture.active = ac;
        _material.SetInt("_Index", frame);
        _material.SetTexture("_Buffer1Tex", _buffers[0]);
        _material.SetTexture("_Buffer2Tex", _buffers[1]);
        _material.SetTexture("_Buffer3Tex", _buffers[2]);
        _material.SetTexture("_Buffer4Tex", _buffers[3]);
        _material.SetPass(1);
        Graphics.DrawProceduralNow(MeshTopology.Triangles, 6, 3);
    }
}
