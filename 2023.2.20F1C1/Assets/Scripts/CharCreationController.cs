using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using MagicaCloth;
using Animancer;
using UnityEngine.EventSystems;

public class CharCreationController : MonoBehaviour
{
    [System.Serializable]
    public class AvatarPartsGroup
    {
        public string groupName;
        public GridLayoutGroup gridLayoutGroup;
        public bool IsUnique = true;
        public List<AvatarPartsItem> partsPrefabList = new List<AvatarPartsItem>();
        public int default_part = 0;
    }
    [System.Serializable]
    public class PartsGroup
    {
        public MagicaAvatar avatar;
        public GameObject partsItemPrefab;
        public GameObject clearItemPrefab;
        public List<AvatarPartsGroup> avatarPartsGroupList = new List<AvatarPartsGroup>();
    }
    [System.Serializable]
    public class MakeupGroup
    {
        public SkinnedMeshRenderer Body;
        public GameObject makeItemPrefab;
        public GridLayoutGroup makeupLayoutGroup;
        public List<MakeupPartsItem> makeupList = new List<MakeupPartsItem>();
        public int default_makeup;
    }
    [System.Serializable]
    public class AnimGroup
    {
        public AnimancerComponent animancer;
        public Avatar humanoidAvatar;
        public Avatar GenericAvatar;
        public GameObject animItemPrefab;
        public VerticalLayoutGroup verticalLayoutGroup;
        //public AnimationClip TouchChest;
        //public AnimationClip TouchCrotch;
        //public AnimationClip FaceCap;
        public List<AnimationClip> animClipList = new List<AnimationClip>();
        public int default_anim;
        [HideInInspector]
        public int current_anim = 0;
    }

    [SerializeField]
    public PartsGroup partsGroup = new PartsGroup();
    [SerializeField]
    public MakeupGroup makeupGroup = new MakeupGroup();
    [SerializeField]
    public AnimGroup animGroup = new AnimGroup();
    void Start()
    {
        Init();
    }
    //void Update()
    //{
    //    bool isOverUI = IsPointerOverUIElement();
    //    bool IsMouseOverGameWindow = !(0 > Input.mousePosition.x || 0 > Input.mousePosition.y || Screen.width < Input.mousePosition.x || Screen.height < Input.mousePosition.y);
    //    if (IsMouseOverGameWindow)
    //    {
    //        //控制摸胸反应
    //        if (Input.GetKeyDown(KeyCode.Z))
    //        {
    //            PlayAnim(animGroup.animancer, animGroup.TouchChest);
    //        }
    //        //控制摸X反应
    //        if (Input.GetKeyDown(KeyCode.X))
    //        {
    //            PlayAnim(animGroup.animancer, animGroup.TouchCrotch);
    //        }
    //        //播放脸部动画
    //        if (Input.GetKeyDown(KeyCode.C))
    //        {
    //            if (animGroup.FaceCap != null)
    //            {
    //                animGroup.animancer.Layers[1].IsAdditive = true;
    //                PlayFaceAnim(animGroup.animancer, animGroup.FaceCap, 1);
    //            }
    //        }
    //    }
    //}

    //private void OnDestroy()
    //{
    //    avatar = null;
    //    partsItemPrefab = null;
    //    clearItemPrefab = null;
    //}

    private void Init()
    {
        for (int i = 0; i < partsGroup.avatarPartsGroupList.Count; i++)
        {
            var group = partsGroup.avatarPartsGroupList[i];
            int group_id = i;

            var first_item = Instantiate(partsGroup.clearItemPrefab);
            var first_ui = first_item.GetComponent<AvatarPartsItemUI>();
            first_ui.Init(group_id, -1, (groud_id, part_id) => { ChangeParts(groud_id, part_id); });
            first_item.transform.SetParent(group.gridLayoutGroup.transform);
            first_item.transform.localScale = Vector3.one;
            for (int j = 0; j < group.partsPrefabList.Count; j++)
            {
                var partPrefab = group.partsPrefabList[j];
                partPrefab.avatar_handle = 0;
                int part_id = j;
                var item = Instantiate(partsGroup.partsItemPrefab);
                var ui = item.GetComponent<AvatarPartsItemUI>();
                ui.Init(partPrefab, group_id, part_id,(groud_id, part_id) => { ChangeParts(groud_id, part_id); });
                item.transform.SetParent(group.gridLayoutGroup.transform);
                item.transform.localScale = Vector3.one;
            }
            if(group.default_part < group.partsPrefabList.Count)
                ChangeParts(group_id, group.default_part);
        }
        for (int i = 0; i < makeupGroup.makeupList.Count; i++)
        {
            var makeupItem = makeupGroup.makeupList[i];
            int makeup_id = i;
            var item = Instantiate(makeupGroup.makeItemPrefab);
            var ui = item.GetComponent<MakeupPartsItemUI>();
            ui.Init(makeupItem, makeup_id, (makeup_id) => { ChangeMakeup(makeup_id); });
            item.transform.SetParent(makeupGroup.makeupLayoutGroup.transform);
            item.transform.localScale = Vector3.one;
        }
        if (makeupGroup.default_makeup < makeupGroup.makeupList.Count)
            ChangeMakeup(makeupGroup.default_makeup);

        for (int i = 0; i < animGroup.animClipList.Count; i++)
        {
            var animClip = animGroup.animClipList[i];
            int anim_id = i;
            var item = Instantiate(animGroup.animItemPrefab);
            var ui = item.GetComponent<PoseAnimItemUI>();
            ui.Init(this,animClip.name,anim_id, (anim_id) => { ChangeAnim(anim_id); });
            item.transform.SetParent(animGroup.verticalLayoutGroup.transform);
            item.transform.localScale = Vector3.one;
        }
        if (animGroup.default_anim < animGroup.animClipList.Count)
            ChangeAnim(animGroup.default_anim);
    }

    private void ChangeParts(int groud_id, int part_id)
    {
        var group = partsGroup.avatarPartsGroupList[groud_id];
        if (part_id < 0)
        {
            foreach (var partItem in group.partsPrefabList)
            {
                if (partItem.avatar_handle != 0)
                {
                    partsGroup.avatar.DetachAvatarParts(partItem.avatar_handle);
                    partItem.avatar_handle = 0;
                }
            }
            return;
        }
        var part = group.partsPrefabList[part_id];
        if (group.IsUnique)
        {
            for (int i = 0; i < group.partsPrefabList.Count; i++)
            {
                var other_part = group.partsPrefabList[i];
                if (other_part.avatar_handle != 0)
                {
                    partsGroup.avatar.DetachAvatarParts(other_part.avatar_handle);
                    other_part.avatar_handle = 0;
                }
            }
            if (part.avatar_handle == 0)
            {
                part.avatar_handle = partsGroup.avatar.AttachAvatarParts(part.gameObject);
                var skinrenders = part.gameObject.transform.GetComponentsInChildren<SkinnedMeshRenderer>();
                foreach (var skinrender in skinrenders)
                {
                    skinrender.updateWhenOffscreen = true;
                }
            }
        }
        else
        {
            if (part.avatar_handle != 0)
            {
                partsGroup.avatar.DetachAvatarParts(part.avatar_handle);
                part.avatar_handle = 0;
            }
            else
                part.avatar_handle = partsGroup.avatar.AttachAvatarParts(part.gameObject);
        }
    }
    private void ChangeMakeup(int makeup_id)
    {
        if (makeup_id >= 0)
        {
            var originMats = makeupGroup.Body.sharedMaterials;
            var makeupItem = makeupGroup.makeupList[makeup_id];
            var targetMats = makeupItem.targetMaterials;
            for (int i = 0; i < originMats.Length; i++)
            {
                foreach (var targetMat in targetMats)
                {
                    if (targetMat.name == originMats[i].name)
                    {
                        originMats[i] = targetMat;
                        var child = makeupGroup.Body.transform.Find(targetMat.name);
                        if (child != null)
                        {
                            var childMesh = child.GetComponent<SkinnedMeshRenderer>();
                            if (childMesh != null)
                                childMesh.sharedMaterial = targetMat;
                        }
                    }
                }
            }
            makeupGroup.Body.sharedMaterials = originMats;
        }
    }
    private void ChangeAnim(int anim_id)
    {
        if (animGroup.animancer != null && anim_id >= 0)
        {
            var animClip = animGroup.animClipList[anim_id];
            bool isChangeAvatar = false;
            if (animClip.isHumanMotion)
            {
                isChangeAvatar = animGroup.animancer.Animator.avatar != animGroup.humanoidAvatar;
                if (isChangeAvatar)
                    animGroup.animancer.Animator.avatar = animGroup.humanoidAvatar;
            }
            else
            {
                isChangeAvatar = animGroup.animancer.Animator.avatar != animGroup.GenericAvatar;
                if(isChangeAvatar)
                    animGroup.animancer.Animator.avatar = animGroup.GenericAvatar;
            }
            if(isChangeAvatar)
                animGroup.animancer.Layers[0].Play(animClip);
            else
                animGroup.animancer.Layers[0].Play(animClip, 0.25f);
            animGroup.current_anim = anim_id;
        }
    }
    private void PlayAnim(AnimancerComponent animancer,AnimationClip animClip,int layerIndex = 0)
    {
        if (animancer != null && animClip != null)
        {
            bool isChangeAvatar = false;
            if (animClip.isHumanMotion)
            {
                isChangeAvatar = animancer.Animator.avatar != animGroup.humanoidAvatar;
                if (isChangeAvatar)
                    animancer.Animator.avatar = animGroup.humanoidAvatar;
            }
            else
            {
                isChangeAvatar = animancer.Animator.avatar != animGroup.GenericAvatar;
                if (isChangeAvatar)
                    animancer.Animator.avatar = animGroup.GenericAvatar;
            }
            if (isChangeAvatar)
                animancer.Layers[layerIndex].Play(animClip).Events.OnEnd = () => animancer.Layers[layerIndex].Play(animGroup.animClipList[animGroup.current_anim]);
            else
                animancer.Layers[layerIndex].Play(animClip, 0.5f,FadeMode.FromStart).Events.OnEnd = () => animancer.Layers[layerIndex].Play(animGroup.animClipList[animGroup.current_anim],0.5f,FadeMode.FromStart); ;
        }
    }
    private void PlayFaceAnim(AnimancerComponent animancer, AnimationClip animClip, int layerIndex = 0)
    {
        if (animancer != null && animClip != null)
        {
            bool isChangeAvatar = false;
            if (animClip.isHumanMotion)
            {
                isChangeAvatar = animancer.Animator.avatar != animGroup.humanoidAvatar;
                if (isChangeAvatar)
                    animancer.Animator.avatar = animGroup.humanoidAvatar;
            }
            else
            {
                isChangeAvatar = animancer.Animator.avatar != animGroup.GenericAvatar;
                if (isChangeAvatar)
                    animancer.Animator.avatar = animGroup.GenericAvatar;
            }
            if (isChangeAvatar)
                animancer.Layers[layerIndex].Play(animClip);
            else
                animancer.Layers[layerIndex].Play(animClip, 0.5f, FadeMode.FromStart);
        }
    }

    //Returns 'true' if we touched or hovering on Unity UI element.
    public bool IsPointerOverUIElement()
    {
        return IsPointerOverUIElement(GetEventSystemRaycastResults());
    }
    //Returns 'true' if we touched or hovering on Unity UI element.
    private bool IsPointerOverUIElement(List<RaycastResult> eventSystemRaysastResults)
    {
        if (eventSystemRaysastResults == null)
            return false;
        for (int index = 0; index < eventSystemRaysastResults.Count; index++)
        {
            RaycastResult curRaysastResult = eventSystemRaysastResults[index];
            if (curRaysastResult.gameObject.layer == LayerMask.NameToLayer("UI"))
                return true;
        }
        return false;
    }


    //Gets all event system raycast results of current mouse or touch position.
    static List<RaycastResult> GetEventSystemRaycastResults()
    {
        PointerEventData eventData = new PointerEventData(EventSystem.current);
        eventData.position = Input.mousePosition;
        List<RaycastResult> raysastResults = new List<RaycastResult>();
        if (EventSystem.current == null)
            return null;
        EventSystem.current.RaycastAll(eventData, raysastResults);
        return raysastResults;
    }
}
