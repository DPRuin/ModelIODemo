//
//  GameViewController.swift
//  ModelIO
//
//  Created by mac126 on 2018/5/21.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import ModelIO
import SceneKit.ModelIO

class GameViewController: UIViewController {

    var scene = SCNScene()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        // let scene = SCNScene(named: "art.scnassets/ship.scn")!
        // 加载战机
        loadFighter()
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // 全光源
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // 环境光
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
        // let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!
        let ship = scene.rootNode.childNodes.first
        // animate the 3d object
        ship?.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        // 允许用户利用各种手势来控制相机，单指旋转，双指平移，缩放手势，双击恢复原位, 默认值为false
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                // material.diffuse.contents = UIImage(named: "art.scnassets/texture.png")
                SCNTransaction.commit()
            }
            /*
             尝试直接通过material的diffuse属性更改贴图，不成功
             而通过shadermodifer，着色修改器就能实现更改贴图效果
             */
            material.emission.contents = UIColor.red
//            let image = UIImage(named: "art.scnassets/Fighter_Diffuse_25.jpg")
//            material.diffuse.contents = image
            
            
            SCNTransaction.commit()
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    /*
     
     */
    /// 通过ModelI/O加载.obj格式3d模型
    func loadFighter() {
        // 加载.obj文件
        guard let url = Bundle.main.url(forResource: "Fighter", withExtension: "obj", subdirectory: "art.scnassets") else {
            fatalError("没有找到模型文件")
        }
        
        // MDLAsset代表3d模型资源内容
        let asset = MDLAsset(url: url)
        // MDLMesh 网格数据
        guard let mesh = asset.object(at: 0) as? MDLMesh else {
            fatalError("没有网格数据")
        }
        
        /* 散射函数 对应Lighting model
         */
        // 创建各种纹理材质
        let scatteringFunction = MDLScatteringFunction()
        // let scatteringFunction = MDLPhysicallyPlausibleScatteringFunction()
        // MDLMaterial 代表材质集合
        let material = MDLMaterial(name: "baseMaterial", scatteringFunction: scatteringFunction)
        material.setTextureProperties([MDLMaterialSemantic.baseColor : "Fighter_Diffuse_25.jpg",
                                       MDLMaterialSemantic.specular : "Fighter_Specular_25.jpg",
                                       MDLMaterialSemantic.emission : "Fighter_Illumination_25.jpg"
                                       ])
        // MDLMaterial(name: <#T##String#>, scatteringFunction: <#T##MDLScatteringFunction#>)
            //
        
        // 将材质应用到每个子网格上
        for submesh in mesh.submeshes! {
            if let submesh  = submesh as? MDLSubmesh {
                submesh.material = material
            }
        }
        
        // 将ModelIO对象包装成scenekit对象，调整大小和位置
        // 需要导入SceneKit.ModelIO框架
        let node = SCNNode(mdlObject: mesh)
        node.position = SCNVector3Make(0, 0, -50)
        node.scale = SCNVector3Make(0.05, 0.05, 0.05)
        
        scene.rootNode.addChildNode(node)
    }

}

extension MDLMaterial {
    
    /// 设置材质
    ///
    /// - Parameter textures: 材质字典， MDLMaterialSemantic对应材质的唯一标识符
    func setTextureProperties(_ textures: [MDLMaterialSemantic : String]) {
        for (key, value) in textures {
            
            guard let url = Bundle.main.url(forResource: value, withExtension: nil, subdirectory: "art.scnassets") else {
                fatalError("没有找到材质\(value)")
            }
            let property = MDLMaterialProperty(name: value, semantic: key, url: url)
            // 设置材质
            setProperty(property)
        }
    }
}
