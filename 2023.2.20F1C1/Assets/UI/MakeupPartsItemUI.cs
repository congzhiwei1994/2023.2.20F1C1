// Magica Cloth.
// Copyright (c) MagicaSoft, 2020-2022.
// https://magicasoft.jp
using UnityEngine;
using UnityEngine.UI;

public class MakeupPartsItemUI : MonoBehaviour
{
    public Image m_Icon;
    public Button m_Button;
    public GameObject m_EqiupCheck;
    private int makeup_id;

    void Start()
    {
    }

    public void Init(MakeupPartsItem makeupItem, int makeup_id, System.Action<int> onClick)
    {
        this.makeup_id = makeup_id;
        if (makeupItem.Icon != null)
            m_Icon.sprite = makeupItem.Icon;

        m_Button.onClick.AddListener(() =>
        {
            onClick(this.makeup_id);
        });
    }
    void Update()
    {
    }
}
