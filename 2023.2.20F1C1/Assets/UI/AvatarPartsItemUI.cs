// Magica Cloth.
// Copyright (c) MagicaSoft, 2020-2022.
// https://magicasoft.jp
using UnityEngine;
using UnityEngine.UI;

public class AvatarPartsItemUI : MonoBehaviour
{
    public Image m_Icon;
    public Button m_Button;
    public GameObject m_EqiupCheck;
    [HideInInspector]
    public AvatarPartsItem avatarPartItem;
    private int ground_id;
    private int part_id;

    void Start()
    {
    }

    public void Init(AvatarPartsItem partItem, int ground_id, int part_id,System.Action<int, int> onClick)
    {
        avatarPartItem = partItem;
        this.ground_id = ground_id;
        this.part_id = part_id;
        if (avatarPartItem.Icon != null)
            m_Icon.sprite = avatarPartItem.Icon;

        m_Button.onClick.AddListener(() =>
        {
            onClick(this.ground_id, this.part_id);
        });
    }
    public void Init(int ground_id, int part_id, System.Action<int, int> onClick)
    {
        this.ground_id = ground_id;
        this.part_id = part_id;

        m_Button.onClick.AddListener(() =>
        {
            onClick(this.ground_id, this.part_id);
        });
    }
    void Update()
    {
        if(avatarPartItem != null)
        m_EqiupCheck.SetActive(avatarPartItem.avatar_handle != 0);
    }
}
