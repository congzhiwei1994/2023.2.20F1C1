using System.IO;
using System.Reflection;
using UnityEditor;
using UnityEditor.ProjectWindowCallback;
using UnityEngine;
public class ProjectWindowUtilEx
{

    [MenuItem("Assets/Create/Shader/URP/SimpleLit")]
    static void CreateUrpSimpleLitShader()
    {
        string path = Application.dataPath + "/3rd/ShaderTemplate/Editor/Template/SimpleLit.shader";
        ProjectWindowUtilEx.CreateScriptUtil(path, "New SimpleLit.shader");
    }

    [MenuItem("Assets/Create/Shader/URP/Lit")]
    static void CreateUrpLitShader()
    {
        string path = Application.dataPath + "/3rd/ShaderTemplate/Editor/Template/Lit.shader";
        ProjectWindowUtilEx.CreateScriptUtil(path, "New LitShader.shader");
    }
    [MenuItem("Assets/Create/Shader/URP/Lit_Simple")]
    static void CreateUrpLitSimpleShader()
    {
        string path = Application.dataPath + "/3rd/ShaderTemplate/Editor/Template/Lit_Simple.shader";
        ProjectWindowUtilEx.CreateScriptUtil(path, "New LitShader.shader");
    }

    [MenuItem("Assets/Create/Shader/URP/Unlit")]
    static void CreateUrpUnLitShader()
    {
        string path = Application.dataPath + "/3rd/ShaderTemplate/Editor/Template/Unlit.shader";
        ProjectWindowUtilEx.CreateScriptUtil(path, "New UnlitShader.shader");
    }

    public static void CreateScriptUtil(string path, string templete)
    {
        ProjectWindowUtil.CreateScriptAssetFromTemplateFile(path, templete);
    }

}