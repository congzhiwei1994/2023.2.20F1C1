using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace JEFFORD
{
    public class SceneController : MonoBehaviour
    {
        private int currentIndex;
        private Action<float> onProgress;
        private Action onFinsh;

        /**
                private static SceneController _instance;
                public static SceneController Instance
                {
                    get
                    {
                        if (_instance == null)
                        {
                            GameObject obj = new GameObject("SceneController");
                            obj.AddComponent<SceneController>();
                        }

                        return _instance;
                    }
                }

                private void Awake()
                {
                    DontDestroyOnLoad(gameObject);
                    if (_instance != null)
                    {
                        throw new Exception("场景中存在多个SceneController");
                        _instance = this;
                    }
                }


                public void LoadScene(int index, Action<float> onProgress, Action onFinsh)
                {
                    this.currentIndex = 1;
                    this.onProgress = onProgress;
                    this.onFinsh = onFinsh;

                    StartCoroutine(LoadScene());
                }
                **/
        
        public void LoadCharacterScene()
        {
            this.currentIndex = 1;
            StartCoroutine(LoadScene());
        }
        
        public void LoadStartScene()
        {
            this.currentIndex = 0;
            StartCoroutine(LoadScene());
        }

        

        private IEnumerator LoadScene()
        {
            yield return null;
            AsyncOperation asyncOperation = SceneManager.LoadSceneAsync(this.currentIndex);
            while (!asyncOperation.isDone)
            {
                yield return null;
                onProgress?.Invoke(asyncOperation.progress);
            }

            yield return new WaitForSeconds(1f);
            onFinsh?.Invoke();
        }
    }
}