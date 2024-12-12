using UnityEngine;
using System.Collections;
using UnityEngine.EventSystems;
using System.Collections.Generic;
//using RealisticEyeMovements;
using DG.Tweening;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering.Universal;

[System.Serializable]
public class CameraPreset
{
	public Vector3 Pos;
	public Vector3 RotateAngles;
	public float height;
	public float offset;
	public float distance;
}
public class CameraController : MonoBehaviour {
	public Transform targetFocus;
    public GameObject targetObj;
	public GameObject UIPanel;
	public Transform mainLight;
	public bool EnableDragObject = false;
    public bool EnableRotateLight = false;
    public float height = 0.0f;
	public float offset = 0.0f;
	public float distance = 3.5f;
	[Range(0.1f, 4f)] public float ZoomWheelSpeed = 4.0f;

	public float minDistance = 1f;
	public float maxDistance = 4f;

	public float xSpeed = 250.0f;
	public float ySpeed = 120.0f;

    public float yMinLimit = -10;
    public float yMaxLimit = 60;

    public float objRotateSpeed = 500.0f;

    //
	private float x = 0.0f;
	private float y = 0.0f;
	
	private float normal_angle=0.0f;

	private float cur_distance=0;

	private float cur_xSpeed=0;
	private float cur_ySpeed=0;
	private float req_xSpeed=0;
	private float req_ySpeed=0;

	private float cur_ObjRotateSpeed=0;
	private float req_ObjRotateSpeed=0;

	private bool DraggingObject=false;
	private bool lastLMBState=false;
	private Collider[] surfaceColliders;
	private float bounds_MaxSize=20;

	private bool showUI = true;
	private bool LookAtPlayer = false;
	private bool RandomHead = false;
	private bool RandomEye = false;
	private bool IsWet = false;
	[SerializeField]
	public CameraPreset CameraPresets1;
	[SerializeField]
	public CameraPreset CameraPresets2;
	[SerializeField]
	public CameraPreset CameraPresets3;
	[SerializeField]
	public CameraPreset CameraPresets4;
	[SerializeField]
	public CameraPreset CameraPresets5;
	[SerializeField]
	public CameraPreset CameraPresets6;
	[SerializeField]
	public CameraPreset CameraPresets7;
	[HideInInspector] public bool disableSteering=false;
	[HideInInspector] public bool isApplyingCameraPreset = false;
	private Quaternion mCharRotation;
	private Quaternion mLightRotation;

	void Start () {
		Vector3 angles = transform.eulerAngles;
		x = angles.y;
		y = angles.x;

		if (targetObj != null && mainLight != null)
		{
			mCharRotation = targetObj.transform.rotation;
			mLightRotation = mainLight.rotation;
		}
		Reset();
	}

	public void DisableSteering(bool state) {
		disableSteering = state;
	}
	void ResetCharAndLighting()
	{
		targetObj.transform.rotation = mCharRotation;
		mainLight.transform.rotation = mLightRotation;
	}
	public void Reset() {
		lastLMBState = Input.GetMouseButton(0);

		disableSteering = false;

		cur_distance = distance;
		cur_xSpeed=0;
		cur_ySpeed=0;
		req_xSpeed=0;
		req_ySpeed=0;
		surfaceColliders = null;

        cur_ObjRotateSpeed = 0;
        req_ObjRotateSpeed = 0;
		
		if (targetObj) {
			Renderer[] renderers = targetObj.GetComponentsInChildren<Renderer>();
			Bounds bounds = new Bounds();
			bool initedBounds=false;
			foreach(Renderer rend in renderers) {
				if (!initedBounds) {
					initedBounds=true;
					bounds=rend.bounds;
				} else {
					bounds.Encapsulate(rend.bounds);
				}
			}
			Vector3 size = bounds.size;
			float dist = size.x>size.y ? size.x : size.y;
			dist = size.z>dist ? size.z : dist;
			bounds_MaxSize = dist;
			cur_distance += bounds_MaxSize*1.2f;
			
			surfaceColliders = targetObj.GetComponentsInChildren<Collider>();
		}
	}
	void ApplyCameraPreset(CameraPreset preset)
	{
        //transform.position = preset.Pos;
        Vector3 angles = preset.RotateAngles;
		//x = angles.y;
		//y = angles.x;
		//height = preset.height;
		//offset = preset.offset;
		//distance = preset.distance;
		isApplyingCameraPreset = true;
		DOTween.To(() => transform.position, x => transform.position = x, preset.Pos, 0.5f);
		DOTween.To(() => this.x, x => this.x = x, angles.y, 0.5f);
		DOTween.To(() => this.y, x => this.y = x, angles.x, 0.5f);
		DOTween.To(() => height, x => height = x, preset.height, 0.5f);
		DOTween.To(() => offset, x => offset = x, preset.offset, 0.5f);
		DOTween.To(() => distance, x => distance = x, preset.distance, 0.5f).OnComplete(() => { isApplyingCameraPreset = false; });
	}
    void LateUpdate () {
		if (Input.GetKeyDown(KeyCode.Alpha1))
		{
			ApplyCameraPreset(CameraPresets1);
		}
		if (Input.GetKeyDown(KeyCode.Alpha2))
		{
			ApplyCameraPreset(CameraPresets2);
		}
		if (Input.GetKeyDown(KeyCode.Alpha3))
		{
			ApplyCameraPreset(CameraPresets3);
		}
		if (Input.GetKeyDown(KeyCode.Alpha4))
		{
			ApplyCameraPreset(CameraPresets4);
		}
		if (Input.GetKeyDown(KeyCode.Alpha5))
		{
			ApplyCameraPreset(CameraPresets5);
		}
		if (Input.GetKeyDown(KeyCode.Alpha6))
		{
			ApplyCameraPreset(CameraPresets6);
		}
		if (Input.GetKeyDown(KeyCode.Alpha7))
		{
			ApplyCameraPreset(CameraPresets7);
		}
		bool isOverUI = IsPointerOverUIElement();
		bool IsMouseOverGameWindow = !(0 > Input.mousePosition.x || 0 > Input.mousePosition.y || Screen.width < Input.mousePosition.x || Screen.height < Input.mousePosition.y);

        if (IsMouseOverGameWindow)
        {
            if (Input.GetKey(KeyCode.UpArrow))
			{
				height += 0.005f;
			}
			if (Input.GetKey(KeyCode.DownArrow))
			{
				height -= 0.005f;
			}
			if (Input.GetKey(KeyCode.LeftArrow))
			{
				offset -= 0.005f;
			}
			if (Input.GetKey(KeyCode.RightArrow))
			{
				offset += 0.005f;
			}
			if (Input.GetKeyDown(KeyCode.R))
			{
				ResetCharAndLighting();
			}
			if (Input.GetKeyDown(KeyCode.J))
			{
				EnableDragObject = !EnableDragObject;
			}
			if (Input.GetKeyDown(KeyCode.K))
			{
				EnableRotateLight = !EnableRotateLight;
			}
			if (Input.GetKeyDown(KeyCode.U))
			{
				showUI = !showUI;
				if (UIPanel != null)
				{
					if (showUI)
						UIPanel.GetComponent<Animator>().Play("Start");
					else
						UIPanel.GetComponent<Animator>().Play("Invisible");
				}
			}
			//if (Input.GetKeyDown(KeyCode.L))
			//{
			//	LookAtPlayer = !LookAtPlayer;
			//	if (targetObj != null)
			//	{
			//		var lookController = targetObj.GetComponent<LookTargetController>();
			//		if (lookController != null)
			//		{
			//			if (LookAtPlayer)
			//			{

			//				lookController.lookAtPlayerRatio = 1.0f;
			//				lookController.stareBackFactor = 1.0f;
			//			}
			//			else
			//			{
			//				lookController.lookAtPlayerRatio = 0.0f;
			//				lookController.stareBackFactor = 0.0f;
			//			}
			//		}
			//	}
			//}
			////控制头部随机动画
			//if (Input.GetKeyDown(KeyCode.H))
			//{
			//	RandomHead = !RandomHead;
			//	if (targetObj != null)
			//	{
			//		var EyeAnimator = targetObj.GetComponent<EyeAndHeadAnimator>();
			//		if (EyeAnimator != null)
			//		{
			//			if (RandomHead)
			//			{

			//				EyeAnimator.headWeight = 1.0f;
			//			}
			//			else
			//			{
			//				EyeAnimator.headWeight = 0.0f;
			//			}
			//		}
			//	}
			//}
			////控制眼部随机动画
			//if (Input.GetKeyDown(KeyCode.E))
			//{
			//	RandomEye = !RandomEye;
			//	if (targetObj != null)
			//	{
			//		var EyeAnimator = targetObj.GetComponent<EyeAndHeadAnimator>();
			//		if (EyeAnimator != null)
			//		{
			//			if (RandomEye)
			//			{

			//				EyeAnimator.eyesWeight = 1.0f;
			//			}
			//			else
			//			{
			//				EyeAnimator.eyesWeight = 0.0f;
			//			}
			//		}
			//	}
			//}
			//控制Rim Light
			if (Input.GetKeyDown(KeyCode.B))
			{
				var rimlight = GameObject.Find("RimLight");
				if (rimlight != null)
				{
					rimlight.GetComponent<Light>().enabled = !rimlight.GetComponent<Light>().enabled;
				}
			}
			//控制湿润效果
			if (Input.GetKeyDown(KeyCode.W))
			{
				IsWet = !IsWet;
				if(IsWet)
					Shader.SetGlobalFloat("RainGlobal", 1.0f);
				else
					Shader.SetGlobalFloat("RainGlobal", 0.0f);
			}
		}

        var mousePosition = Input.mousePosition;
		if (mousePosition.x < Screen.width / 3 && mousePosition.y > (Screen.height - Screen.height / 3))
			return;

		if (targetObj && targetFocus && IsMouseOverGameWindow && !isOverUI && !isApplyingCameraPreset) 
		{

			if (!lastLMBState && Input.GetMouseButton(0)) {
				// mouse down
				DraggingObject=false;
                if(EnableDragObject == true)
			        DraggingObject=true;

			} else if (lastLMBState && !Input.GetMouseButton(0)) {
				// mouse up
				DraggingObject=false;
			}
			lastLMBState = Input.GetMouseButton(0);

			if (DraggingObject) {
				if (Input.GetMouseButton(0) && !disableSteering) {
                    req_ObjRotateSpeed += (Input.GetAxis("Mouse X") * objRotateSpeed * 0.02f - req_ObjRotateSpeed) *Time.deltaTime*10;
				} else {
                    req_ObjRotateSpeed += (0 - req_ObjRotateSpeed) *Time.deltaTime*4;
				}

				req_xSpeed += (0 - req_xSpeed)*Time.deltaTime*4;
				req_ySpeed += (0 - req_ySpeed)*Time.deltaTime*4;
			}
            else
			{
				if (Input.GetMouseButton(0) && !disableSteering) {
					req_xSpeed += (Input.GetAxis("Mouse X") * xSpeed * 0.02f - req_xSpeed)*Time.deltaTime*10;
					req_ySpeed += (Input.GetAxis("Mouse Y") * ySpeed * 0.02f - req_ySpeed)*Time.deltaTime*10;
				} else {
					req_xSpeed += (0 - req_xSpeed)*Time.deltaTime*4;
					req_ySpeed += (0 - req_ySpeed)*Time.deltaTime*4;
				}

                req_ObjRotateSpeed += (0 - req_ObjRotateSpeed) *Time.deltaTime*4;
				//req_ObjySpeed += (0 - req_ObjySpeed)*Time.deltaTime*4;
                if (EnableDragObject == true)
                {
                    req_ObjRotateSpeed = 0.0f;
                    cur_ObjRotateSpeed = 0.0f;
                }
			}

			cur_ObjRotateSpeed += (req_ObjRotateSpeed - cur_ObjRotateSpeed) *Time.deltaTime*20;
            if (EnableDragObject == true)
            {
                if (EnableRotateLight == true)
                {
                    if(mainLight != null)
                    mainLight.transform.Rotate(Vector3.up, -cur_ObjRotateSpeed, Space.World);
                }
                else
                targetObj.transform.Rotate(Vector3.up, -cur_ObjRotateSpeed, Space.World);
            }

			cur_xSpeed += (req_xSpeed - cur_xSpeed) * Time.deltaTime * 20;
			cur_ySpeed += (req_ySpeed - cur_ySpeed) * Time.deltaTime * 20;
			x += cur_xSpeed;
			y -= cur_ySpeed;
			y = ClampAngle(y, yMinLimit + normal_angle, yMaxLimit + normal_angle);

			distance -= Input.GetAxis("Mouse ScrollWheel") * ZoomWheelSpeed;
			distance = Mathf.Clamp(distance, minDistance, maxDistance);
		}
		if (surfaceColliders != null && surfaceColliders.Length > 0)
		{
			RaycastHit hitInfo = new RaycastHit();
			Vector3 vdir = Vector3.Normalize(targetFocus.position - transform.position);
			float reqDistance = 0.01f;
			bool surfaceFound = false;
			foreach (Collider surfaceCollider in surfaceColliders)
			{
				if (surfaceCollider.Raycast(new Ray(transform.position - vdir * bounds_MaxSize, vdir), out hitInfo, Mathf.Infinity))
				{
					reqDistance = Mathf.Max(Vector3.Distance(hitInfo.point, targetFocus.position) + distance, reqDistance);
					surfaceFound = true;
				}
			}
			if (surfaceFound)
			{
				cur_distance += (reqDistance - cur_distance) * Time.deltaTime * 4;
			}
		}
		else
			cur_distance = distance;
		Quaternion rotation = Quaternion.Euler(y, x, 0);
		Vector3 position = rotation * new Vector3(0.0f + offset, 0.0f + height, -cur_distance) + targetFocus.position;
		transform.rotation = rotation;
		transform.position = position;
	}
	
	static float ClampAngle (float angle, float min, float max) {
		if (angle < -360)
			angle += 360;
		if (angle > 360)
			angle -= 360;
		return Mathf.Clamp (angle, min, max);
	}
	
	public void set_normal_angle(float a) {
		normal_angle=a;
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