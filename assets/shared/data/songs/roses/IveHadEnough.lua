function onCreatePost()
    initShaderFromSource('vignette', 'VignetteEffect')
    setCameraShader('hud', 'vignette')
    setCameraShader('game', 'vignette')
    setShaderProperty('vignette', 'strength', 12)
    setShaderProperty('vignette', 'size', 0.9)

    initShaderFromSource('rain', 'RainEffect')
    setCameraShader('game', 'rain')
end