using UnityEngine;
using System.Collections;
using System.Linq;

class SlitScanCam : MonoBehaviour
{
    [SerializeField] Shader _shader = null;

    Material _material;
    RenderTexture[] _buffers;
    WebCamTexture _webcam;

    RenderTexture AllocateBuffer(int index)
    {
        var rt = new RenderTexture(4096, 4096, 0, RenderTextureFormat.RGB565);
        rt.name = $"Buffer{index}";
        rt.Create();
        return rt;
    }

    IEnumerator Start()
    {
        Application.targetFrameRate = 60;

        yield return
          Application.RequestUserAuthorization(UserAuthorization.WebCam);

        _material = new Material(_shader);

        _buffers =
          Enumerable.Range(0, 8).Select(i => AllocateBuffer(i)).ToArray();

        _webcam = new WebCamTexture();
        _webcam.Play();
    }

    void OnPostRender()
    {
        if (_webcam == null) return;

        var frame = Time.frameCount;
        var index = frame >> 4 & 7;
        var ox = ((frame     ) & 3) / 4.0f;
        var oy = ((frame >> 2) & 3) / 4.0f;

        var ac = RenderTexture.active;

        RenderTexture.active = _buffers[index];
        _material.SetFloat("_VFlip", _webcam.videoVerticallyMirrored ? 1 : 0);
        _material.SetVector("_Offset", new Vector2(ox, oy));
        _material.SetTexture("_WebCamTex", _webcam);
        _material.SetPass(0);
        Graphics.DrawProceduralNow(MeshTopology.Triangles, 6, 1);

        RenderTexture.active = ac;
        _material.SetInt("_Index", frame);
        _material.SetTexture("_Buffer0Tex", _buffers[0]);
        _material.SetTexture("_Buffer1Tex", _buffers[1]);
        _material.SetTexture("_Buffer2Tex", _buffers[2]);
        _material.SetTexture("_Buffer3Tex", _buffers[3]);
        _material.SetTexture("_Buffer4Tex", _buffers[4]);
        _material.SetTexture("_Buffer5Tex", _buffers[5]);
        _material.SetTexture("_Buffer6Tex", _buffers[6]);
        _material.SetTexture("_Buffer7Tex", _buffers[7]);
        _material.SetPass(1);
        Graphics.DrawProceduralNow(MeshTopology.Triangles, 6, 1);
    }
}
