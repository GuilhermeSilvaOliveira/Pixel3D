using UnityEngine;

[RequireComponent (typeof(Camera))]
[ExecuteInEditMode]
public class PixelPerfect3D : MonoBehaviour
{
    private Camera cam;

    [Header("Control texture and resolution")]
    [Min(1)]
    public Vector2Int resolution = new Vector2Int(320, 180);
    public RenderTextureFormat textureFormat = RenderTextureFormat.ARGB32;
    public FilterMode filterMode = FilterMode.Point;
    [Header("Control color steps RGB")]
    [Min(0)]
    public Vector3Int ColorSteps =new Vector3Int(32, 32, 32);
    
    
    public bool moveOn = true;
    public float moveSpeed = 5;

    public Camera camView;
    public MeshRenderer quad;
    
    public Transform targetFollow;
    public Vector3 targetFollowOffset;

    private RenderTexture rt;
    float pixelSize;
    

    void Start()
    {
        cam = GetComponent<Camera>();
        camView.orthographicSize = cam.orthographicSize;

        GenerateQuad();
        GenerateTexture(resolution);
    }

    
    void Update()
    {
        
        Shader.SetGlobalVector("_ColorSteps", (Vector3)ColorSteps);
        pixelSize = 2 * cam.orthographicSize / cam.pixelHeight;

        if (targetFollow == null) return;
        if (moveOn == true)
        {
            GenericMovement();
            transform.position = Snap(targetFollow.position + targetFollowOffset);
        }
        else { transform.position = Snap(targetFollow.position + targetFollowOffset); }
          
    }

    

    public void GenerateTexture(Vector2Int resolution)
    {
        /*
        Sumario : gera um RenderTexture(textura) de visualizao em tela
        e repassa essa textura para uma variavel global de shader

        Summary: Generate a render texture for on-screen display
        and pass this texture to a global shader variable.
        */

        if (rt != null)
        {
            cam.targetTexture = null;
            rt.Release();
            DestroyImmediate(rt);
        }

        var texture = new RenderTexture(resolution.x, resolution.y,16,textureFormat);
        texture.filterMode = filterMode;
        cam.targetTexture = texture;
        rt = cam.targetTexture;
        Shader.SetGlobalTexture("_TextureDow", rt);
        Shader.SetGlobalVector("_PixelResolution", (Vector2)resolution); //nesessario para o shader de PixelSnap ficar sempre alinhado a resolucao da camera
                                                                         //This is necessary for the PixelSnap shader to always be aligned with the camera resolution   
    }


    void GenerateQuad()
    {
        /*
        Sumario: calcula e ajusta o tamanho do quad para o tamanho correto da camView e repassa o shader de textura para o mesmo

        Summary: Calculates and adjusts the quad size to the correct camView size and passes the texture shader to it.
        */

        var camViewComponent = camView.GetComponent<Camera>();

        var shader = Shader.Find("Shader Graphs/ShaderTexture");
        
        float height = camViewComponent.orthographicSize * 2;
        float width = height * camViewComponent.aspect;    
        quad.transform.localScale =new Vector3(width,height);
        quad.GetComponent<MeshRenderer>().material.shader = shader;
    }


    Vector3 Snap(Vector3 worldPosition)
    {
        var localPos = transform.InverseTransformPoint(worldPosition);

        localPos.x = Mathf.Round(localPos.x / pixelSize) * pixelSize;
        localPos.y = Mathf.Round(localPos.y / pixelSize) * pixelSize;
        localPos.z = Mathf.Round(localPos.z / pixelSize) * pixelSize;

        var snap = transform.TransformPoint(localPos);
        return snap;

    }


    void GenericMovement()
    {
        
        float y = Input.GetAxisRaw("Vertical");
        float x = Input.GetAxisRaw("Horizontal");
        Vector3 inputDir =new Vector3(x,y,0);
       
        Vector3 moveDir = targetFollow.up * inputDir.y + targetFollow.right * inputDir.x;
        targetFollow.position += moveDir * moveSpeed * Time.deltaTime;
    }

    void OnDisable()
    {
        if (rt != null)
        {
            cam.targetTexture = null;
            rt.Release();
            DestroyImmediate(rt);
        }
    }

}
