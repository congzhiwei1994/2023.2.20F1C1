// Magica Cloth.
// Copyright (c) MagicaSoft, 2020-2022.
// https://magicasoft.jp
using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class PoseAnimItemUI : MonoBehaviour
{
    public TextMeshProUGUI text;
    public Button m_Button;

    public GameObject m_AnimCheck;
    private int anim_id;
    private CharCreationController controller;

    void Start()
    {
    }

    public void Init(CharCreationController controller,string animName,int anim_id,System.Action<int> onClick)
    {
        this.controller = controller;
        text.text = animName;
        this.anim_id = anim_id;

        m_Button.onClick.AddListener(() =>
        {
            onClick(this.anim_id);
        });
    }
    void Update()
    {
        if (m_AnimCheck != null)
            m_AnimCheck.SetActive(controller.animGroup.current_anim == anim_id);
    }
}
