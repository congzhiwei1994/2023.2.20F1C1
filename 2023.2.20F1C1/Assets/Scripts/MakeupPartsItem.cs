using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class MakeupPartsItem : MonoBehaviour
{
    public Sprite Icon;
    public List<Material> targetMaterials;
    [HideInInspector]
    public int avatar_handle;
    void Start()
    {
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
