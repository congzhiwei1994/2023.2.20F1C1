using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class GameController : MonoBehaviour
{
    public Camera camera;
    private MouseOrbit mouseOrbit;

    private void Awake()
    {
        if (camera == null)
        {
            camera = Camera.main;
        }
        mouseOrbit = camera.gameObject.GetComponent<MouseOrbit>();
    }

    public void ExitGame()
    {
#if UNITY_EDITOR
        EditorApplication.isPlaying = false;
#else
  Application.Quit();
#endif
    }

    public void SetHeadCamera()
    {
        // mouseOrbit.distance = 1.5f;
        // mouseOrbit.minDistance = 1.5f;
        // mouseOrbit.maxDistance = 1.5f;
        camera.gameObject.GetComponent<MouseOrbit>().distance = 1.5f;
        camera.gameObject.GetComponent<MouseOrbit>().minDistance = 1.5f;
        camera.gameObject.GetComponent<MouseOrbit>().maxDistance = 1.5f;
    }
    
    public void SetFullBodyHeadCamera()
    {
        // mouseOrbit.distance = 1.5f;
        // mouseOrbit.minDistance = 1.5f;
        // mouseOrbit.maxDistance = 1.5f;
        camera.gameObject.GetComponent<MouseOrbit>().distance = 7f;
        camera.gameObject.GetComponent<MouseOrbit>().minDistance = 7f;
        camera.gameObject.GetComponent<MouseOrbit>().maxDistance = 7f;
    }
}