import
  std/macros


proc liveViewScript*(): NimNode = quote do:
  tScript:"""
const x=document.getElementById("scripts");const a=document.getElementById("app");
socketToSsr.onmessage=function(m){
const[ac,dt]=m.data.split(/:([\s\S]*)/);
switch(ac){
case"script":x.innerHTML="";const e1=document.createRange().createContextualFragment(dt);x.append(e1);break;
case"rerender":const d=phtml(dt).querySelector("#app");renderVdom(d);break;
case"route":window.location.replace(dt);break;
case"bck":window.history.back();break;
case"frwrd":window.history.forward();break;
default:break}};
function phtml(s){const d=new DOMParser().parseFromString(s,"text/html");cln(d.body);return d.body;}
function cln(node){
  for(let n=0;n<node.childNodes.length;n++){
    let c=node.childNodes[n];
    if(c.nodeType === 8 || (c.nodeType===3 && !/\S/.test(c.nodeValue) && c.nodeValue.includes('\n'))){
      node.removeChild(c);n--;
    }else if(c.nodeType===1){cln(c);}
  }
}
function ist(a,b){
  if(a.nodeType===b.NodeType && a.nodeType===1)return a.nodeName.toLowerCase()===b.nodeName.toLowerCase();
  return a.nodeType===b.nodeType;
}
function ai(e){
  const a={};if(!e.attributes||e.attributes.length===0)return a;
  for(let i of e.attributes)a[i.nodeName]=i.nodeValue;
  return a;
}
function pat(vd,d){
  let vda=ai(vd);let da=ai(d);if(vda==da)return;
  Object.keys(vda).forEach((k,i)=>{
  if(!d.getAttribute(k)){d.setAttribute(k,vda[k]);
  }else if(d.getAttribute(k)){if(vda[k]!=da[k])d.setAttribute(k,vda[k]);}});
  Object.keys(da).forEach((k,i)=>{if(!vd.getAttribute(k))d.removeAttribute(k);});
}
function diff(vd,d){
  if(!d.hasChildNodes()&&vd.hasChildNodes()){
    for(var i=0;i<vd.childNodes.length;i++)d.append(vd.childNodes[i].cloneNode(true));
  }else{
    if(vd.isEqualNode(d))return;
    if(d.childNodes.length > vd.childNodes.length) {
      let count=d.childNodes.length-vd.childNodes.length;
      if(count>0)for(;count>0;count--)d.childNodes[d.childNodes.length-count].remove();
    }
    for(var i=0;i<vd.childNodes.length;i++) {
      if (!d.childNodes[i]) {
        d.append(vd.childNodes[i].cloneNode(true));
      }else if(ist(vd.childNodes[i],d.childNodes[i])) {
        if(vd.childNodes[i].nodeType===3){
          if(vd.childNodes[i].textContent != d.childNodes[i].textContent)d.childNodes[i].textContent=vd.childNodes[i].textContent;
        }else{pat(vd.childNodes[i], d.childNodes[i])}
      }else{d.childNodes[i].replaceWith(vd.childNodes[i].cloneNode(true));}
      if(vd.childNodes[i].nodeType!==3)diff(vd.childNodes[i],d.childNodes[i])
    }
  }
}
function renderVdom(vd,f){
  let _a=document.activeElement;diff(vd,document.getElementById('app'));
  if(_a.hasAttribute('id')){
    let _ae=document.getElementById(_a.id);
    if(_ae){
      _ae.focus();
      if(_ae.nodeName==="INPUT" || _ae.nodeName==="TEXTAREA"){
        let _0=_a;let curr=_ae;
        curr.setSelectionRange(_0.selectionStart,_0.selectionEnd,_0.selectionDirection);
      }
    }
  }
}
function isObjLiteral(_o){
  var _t=_o;return typeof _o !=="object"||_o===null?false : function(){
    while(!false){
      if(Object.getPrototypeOf(_t=Object.getPrototypeOf(_t))===null)break;
    }return Object.getPrototypeOf(_o)===_t;
  }()
}
function complex(e){const i=typeof e === "function";const j=typeof e === "object" && !isObjLiteral(e);return i||j;}
function se(e,x){
  const r={};
  for(const k in e){
    if(!e[k])continue;
    if(typeof e[k] !== "function" && typeof e[k]!=="object"){
      r[k]=e[k];
    }else if(!(r[k] in x)&&x.length<2&&e[k]!=="function"){
      r[k]=se(e[k],x.concat([e[k]]));
    }
  }
  return r;
}
function ceh(i,e){
  let o=se(e,[e]);o['eventName']=o.constructor.name;
  socketToSsr.send(JSON.stringify({action:"callEventHandler",idx:i,event:o}));
}
function cceh(c,i,e){
  let o=se(e,[e]);o['eventName']=o.constructor.name;
  socketToSsr.send(JSON.stringify({action:"callComponentEventHandler",idx:i,event:o,componentId:c}));
}"""
