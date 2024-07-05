import
  std/macros


proc liveViewScript*(): NimNode = quote do:
  tScript:"""
const x=document.getElementById("scripts");const a=document.getElementById("app");
const _cd = {};
socketToSsr.onmessage=function(m){
const res=JSON.parse(m.data);switch(res.action){
case"script":x.innerHTML="";const e1=document.createRange().createContextualFragment(res.data);x.append(e1);break;
case"rerender":const d=phtml(res.data).querySelector("#app");renderVdom(d);break;
case"route":window.location.replace(res.data);break;
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
  var attrs={};
  if(!e.attributes || e.attributes.length===0)return attrs;
  for(let i of e.attributes)attrs[i.nodeName]=i.nodeValue;
  return attrs;
}
function pat(vd, d){
  let vdomattrs=ai(vd);
  let domattrs=ai(d);
  if(vdomattrs==domattrs)return;
  Object.keys(vdomattrs).forEach((k,i)=>{
  if(!d.getAttribute(k)){d.setAttribute(k,vdomattrs[k]);
  }else if(d.getAttribute(k)){if(vdomattrs[k]!=domattrs[k])d.setAttribute(k,vdomattrs[k]);}});
  Object.keys(domattrs).forEach((k,i)=>{if(!vd.getAttribute(k))d.removeAttribute(k);});
}
function diff(vd, d){
  if(!d.hasChildNodes() && vd.hasChildNodes()){
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
  let actv=document.activeElement;
  diff(vd, document.getElementById('app'));
  if(actv.hasAttribute('id')){
    let actvElem=document.getElementById(actv.id);
    if(actvElem){
      actvElem.focus();
      if(actvElem.nodeName==="INPUT" || actvElem.nodeName==="TEXTAREA"){
        let old=actv;
        let curr=actvElem;
        curr.setSelectionRange(old.selectionStart,old.selectionEnd,old.selectionDirection);
      }
    }
  }
}
function isObjLiteral(_o){
  var _t=_o;
  return typeof _o !=="object"||_o===null?false : function (){
    while(!false) {
      if(Object.getPrototypeOf(_t=Object.getPrototypeOf(_t))===null)break;
    }
    return Object.getPrototypeOf(_o)===_t;
  }()
}
function complex(e){
  const i=typeof e === "function";
  const j=typeof e === "object" && !isObjLiteral(e);
  return i||j;
}
function se(e, x){
  const r={};
  for(const k in e){
    if(!e[k]){continue;}
    if(typeof e[k] !== "function" && typeof e[k]!=="object"){
      r[k]=e[k];
    }else if(!(r[k] in x)&&x.length<2&&e[k]!=="function"){
      r[k]=se(e[k],x.concat([e[k]]));
    }
  }
  return r;
}
function ceh(i,e){
  let ev=se(e,[e]);ev['eventName']=ev.constructor.name;
  socketToSsr.send(JSON.stringify({
    action:"callEventHandler",idx:i,event:ev
  }));
}
function cceh(c,i,e){
  let ev=se(e,[e]);ev['eventName']=ev.constructor.name;
  socketToSsr.send(JSON.stringify({
    action:"callComponentEventHandler",idx:i,event:ev,componentId:c
  }));
}"""
