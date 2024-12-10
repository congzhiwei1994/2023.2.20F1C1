using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteAlways]
public class BackgroundAlign : MonoBehaviour
{
    [Header("需要对齐的Quad")] public GameObject quad;

    private Camera camera;

    // public GameObject uiQuad;
    [Header("图片实际大小 ")] public Vector2 bgsize = new Vector2(1920, 1080);

    public float scale = 1;

    public void Align(GameObject gameObject, Camera cam, float dis)
    {
        if (gameObject == null)
        {
            return;
        }

        var design = new Vector2(Screen.width, Screen.height);
        if (Mathf.Abs(design.y - 1080f) > 0.1f || (design.x < 1920 || design.x > 2400))
        {
            Debug.LogError("Game视图的分辨 应该设置为 x * 1080, x范围(1920, 2400), 如2200*1080");
            return;
        }

        // float farClipPlane = dis;
        //位置
        gameObject.transform.position = cam.transform.position + cam.transform.forward * dis;
        //旋转
        gameObject.transform.rotation = cam.transform.rotation;
        //大小
        var fov = cam.fieldOfView * UnityEngine.Mathf.Deg2Rad;

        var heightInWorld = UnityEngine.Mathf.Tan(fov * 0.5f) * dis * 2;
        var widthInWorld = heightInWorld * cam.aspect;

        var realHeightInWorld = heightInWorld * bgsize.y / design.y;
        var realWidthInWorld = widthInWorld * bgsize.x / design.x;
        gameObject.transform.localScale = new Vector3(realWidthInWorld * scale, realHeightInWorld * scale, 1f);
    }

    private void Start()
    {
        if (camera == null)
        {
            GetCamera();
        }
    }

    private void GetCamera()
    {
        camera = this.GetComponent<Camera>();
    }

    private void Update()
    {
        if (camera == null)
        {
            GetCamera();
            Debug.LogError("GetCamera()");
        }

        this.Align(quad, camera, camera.farClipPlane - 0.1f);
        // this.Align(uiQuad, cam, cam.nearClipPlane);
    }
}