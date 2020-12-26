using UnityEngine;
using System.Collections;

class SlitScanCam : MonoBehaviour
{
    [SerializeField] Shader _shader = null;

    const int Resolution = 256;

    Material _material;
    Texture2DArray _buffer;
    WebCamTexture _webcam;
    int _effectType;

    IEnumerator Start()
    {
        Application.targetFrameRate = 60;

        yield return Application.RequestUserAuthorization
          (UserAuthorization.WebCam);

        _material = new Material(_shader);

        _buffer = new Texture2DArray
          (512, 512, Resolution, TextureFormat.RGB565, false);
        _buffer.filterMode = FilterMode.Bilinear;
        _buffer.wrapMode = TextureWrapMode.Clamp;

        _webcam = new WebCamTexture();
        _webcam.Play();
    }

    void Update()
    {
        if (Input.GetMouseButtonDown(0))
            _effectType = (_effectType + 1) % 3;
    }

    void OnPostRender()
    {
        if (_webcam == null) return;

        var frame = Time.frameCount & (Resolution - 1);

        var ac = RenderTexture.active;
        Graphics.ConvertTexture(_webcam, 0, _buffer, frame);
        RenderTexture.active = ac;

        _material.SetTexture("_BufferTex", _buffer);
        _material.SetFloat("_Axis", _effectType == 0 ? 1 : 0);
        _material.SetFloat("_VFlip", _webcam.videoVerticallyMirrored ? 1 : 0);
        _material.SetInt("_Frame", frame);
        _material.SetPass(_effectType == 2 ? 1 : 0);
        Graphics.DrawProceduralNow(MeshTopology.Triangles, 6, 1);
    }
}
