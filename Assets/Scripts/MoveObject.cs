using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MoveObjetct : MonoBehaviour
{

    
    public float altura = 1f;         
    public float velocidade = 1f;     

    [Header("Rotação")]
    public Vector3 eixoRotacao = Vector3.up; 
    public float velocidadeRotacao = 90f;

    public bool move = true;
    public bool rotate = true;

    private Vector3 posicaoInicial;

    void Start()
    {
        posicaoInicial = transform.position;
    }

    void Update()
    {
        if (move == true)
        {
            float deslocamentoY = Mathf.Sin(Time.time * velocidade) * altura;
            transform.position = posicaoInicial + Vector3.up * deslocamentoY;
        }

        if (rotate == true)
        {
            transform.Rotate(eixoRotacao, velocidadeRotacao * Time.deltaTime, Space.Self);
        }
    }
}
