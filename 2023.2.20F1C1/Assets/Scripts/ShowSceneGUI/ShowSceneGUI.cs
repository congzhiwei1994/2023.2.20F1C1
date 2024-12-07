using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShowSceneGUI : MonoBehaviour
{
    public Camera headCamera;
    public Camera bodyCamera;
    public GameObject ShirleyLee;

    private void OnEnable()
    {
        headCamera.gameObject.SetActive(true);
        bodyCamera.gameObject.SetActive(false);
    }

    void OnGUI()
    {
        if (GUI.Button(new Rect(10, 10, 100, 30), "Head"))
        {
            headCamera.gameObject.SetActive(true);
            bodyCamera.gameObject.SetActive(false);
        }

        if (GUI.Button(new Rect(10, 45, 100, 30), "Body"))
        {
            headCamera.gameObject.SetActive(false);
            bodyCamera.gameObject.SetActive(true);
        }
    }

    private void OnDisable()
    {
        headCamera.gameObject.SetActive(true);
        bodyCamera.gameObject.SetActive(false);
    }
}