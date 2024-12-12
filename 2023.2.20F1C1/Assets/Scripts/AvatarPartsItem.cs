using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class AvatarPartsItem : MonoBehaviour
{
    public Sprite Icon;
    [HideInInspector]
    [System.NonSerialized]
    public int avatar_handle = 0;
    //public bool isWet = false;
    void Start()
    {
    }

    // Update is called once per frame
    void Update()
    {
    }
}
