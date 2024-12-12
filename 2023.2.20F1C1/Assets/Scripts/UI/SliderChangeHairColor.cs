using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SliderChangeHairColor : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
    public void OnSliderValueChange(float value)
    {
        Shader.SetGlobalFloat("GlobalHairControl", 1.0f);
        Shader.SetGlobalFloat("GlobalChange",value);
    }
    private void OnDisable()
    {
        Shader.SetGlobalFloat("GlobalHairControl", 0.0f);
        Shader.SetGlobalFloat("GlobalChange", 0.0f);
    }
}
