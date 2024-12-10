using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace JEFFORD
{
    public class ViewBase : MonoBehaviour
    {
        public virtual void Show()
        {
            gameObject.SetActive(true);
        }

        public virtual void Hide()
        {
            gameObject.SetActive(false);
        }
    }
}