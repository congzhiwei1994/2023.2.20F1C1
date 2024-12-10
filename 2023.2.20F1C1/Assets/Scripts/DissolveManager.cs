using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DissolveManager : MonoBehaviour
{
    public GameObject dissolveGo;
    private List<Material> dissolveMaterials;
    private string dissolveMatName = "DissolveFactor";
    private float dissolveTime = 0;

    private void OnEnable()
    {
        dissolveTime = 0;
        var skinRenderer = dissolveGo.GetComponentInChildren<SkinnedMeshRenderer>();
        var matCount = skinRenderer.materials.Length;
        Debug.LogError(matCount);
    }


    // Update is called once per frame
    void Update()
    {
        dissolveTime += Time.deltaTime;
    }

    private void OnDisable()
    {
    }

    private void SetMaterial(Material material)
    {
        material.SetFloat(dissolveMatName, 1);
    }
}