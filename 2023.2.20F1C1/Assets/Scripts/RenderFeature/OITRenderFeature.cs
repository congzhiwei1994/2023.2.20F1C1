using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace JEFFORD.RENDER
{
    public class OITRenderFeature : ScriptableRendererFeature
    {
        [System.Serializable]
        public class Setting
        {
            public Material Material;
            public RenderPassEvent PassEvent = RenderPassEvent.AfterRenderingTransparents;
        }

        public Setting setting = new Setting();
        private OITRenderPass pass;

        public override void Create()
        {
            pass = new OITRenderPass(setting);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            pass.renderPassEvent = setting.PassEvent;
            renderer.EnqueuePass(pass);
        }
    }
}