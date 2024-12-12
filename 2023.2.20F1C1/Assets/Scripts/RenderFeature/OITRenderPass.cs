using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace JEFFORD.RENDER
{
    public class OITRenderPass : ScriptableRenderPass
    {
        private OITRenderFeature.Setting _setting;

        public OITRenderPass(OITRenderFeature.Setting _setting)
        {
            this._setting = _setting;
        }

        
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
        }
    }
}